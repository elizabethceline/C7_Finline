//
//  ProfileViewModel.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import Combine
import Foundation
import SwiftData
import CloudKit

class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var points: Int = 0
    @Published var productiveHours: [ProductiveHours] = DayOfWeek.allCases.map {
        ProductiveHours(day: $0)
    }
    @Published var bestFocusTime: TimeInterval = 0
    @Published var goals: [Goal] = []
    @Published var tasks: [GoalTask] = []
    @Published var isLoading = false
    @Published var error: String = ""

    @Published var isEditingName = false
    @Published var tempUsername = ""

    private var userProfile: UserProfile?
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    private let networkMonitor: NetworkMonitor
    private let userProfileManager: UserProfileManager
    private let goalManager: GoalManager
    private let taskManager: TaskManager
    
    // MARK: - Public Accessors
    var userProfileManagerInstance: UserProfileManager { userProfileManager }
    var networkMonitorInstance: NetworkMonitor { networkMonitor }

    @MainActor
    var userRecordID: CKRecord.ID? {
        get async {
            do {
                return try await CloudKitManager.shared.fetchUserRecordID()
            } catch {
                print("Failed to get user record ID: \(error)")
                return nil
            }
        }
    }

    
    var errorMessage = ""

    var isSignedInToiCloud: Bool {
        CloudKitManager.shared.isSignedInToiCloud
    }

    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.userProfileManager = UserProfileManager(
            networkMonitor: networkMonitor
        )
        self.goalManager = GoalManager(networkMonitor: networkMonitor)
        self.taskManager = TaskManager(networkMonitor: networkMonitor)

        observeNetworkStatus()
    }

    @MainActor
    func setModelContext(_ context: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = context
        loadDataFromSwiftData()

        if networkMonitor.isConnected {
            Task {
                await syncPendingItems()
            }
        }

        fetchUserProfile()
    }

    // check if online
    private func observeNetworkStatus() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    if self.isSignedInToiCloud, self.modelContext != nil {
                        Task { @MainActor in
                            await self.syncPendingItems()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // load data
    @MainActor
    private func loadDataFromSwiftData() {
        guard let modelContext = modelContext else { return }

        do {
            // Load profile
            let profileDescriptor = FetchDescriptor<UserProfile>()
            if let profile = try modelContext.fetch(profileDescriptor).first {
                updatePublishedProfile(profile)
            }

            // Load goals
            let goalDescriptor = FetchDescriptor<Goal>(
                sortBy: [SortDescriptor(\.due, order: .forward)]
            )
            let goals = try modelContext.fetch(goalDescriptor)
            updatePublishedGoals(goals)

            // Load tasks
            let taskDescriptor = FetchDescriptor<GoalTask>()
            let tasks = try modelContext.fetch(taskDescriptor)
            updatePublishedTasks(tasks)
        } catch {
            self.error =
                "Failed to load local data: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func updatePublishedProfile(_ profile: UserProfile?) {
        self.userProfile = profile
        self.username = profile?.username ?? ""
        self.points = profile?.points ?? 0
        self.productiveHours =
            profile?.productiveHours
            ?? DayOfWeek.allCases.map {
                ProductiveHours(day: $0)
            }
        self.bestFocusTime = profile?.bestFocusTime ?? 0
    }

    @MainActor
    private func updatePublishedGoals(_ goals: [Goal]) {
        self.goals = goals
    }

    @MainActor
    private func updatePublishedTasks(_ tasks: [GoalTask]) {
        self.tasks = tasks
    }

    // fetch + create/update user profile
    @MainActor
    func fetchUserProfile() {
        guard let modelContext = modelContext, isSignedInToiCloud else {
            return
        }

        Task {
            do {
                let userRecordID = try await CloudKitManager.shared
                    .fetchUserRecordID()
                let profile = try await userProfileManager.fetchProfile(
                    userRecordID: userRecordID,
                    modelContext: modelContext
                )

                updatePublishedProfile(profile)
                await fetchGoals()

            } catch {
                self.error =
                    "Failed to fetch user profile: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    func saveUserProfile(
        username: String,
        productiveHours: [ProductiveHours],
        points: Int,
        bestFocusTime: TimeInterval? = nil
    ) {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let currentProfile =
                try modelContext.fetch(descriptor).first ?? self.userProfile

            guard let userProfile = currentProfile else { return }

            userProfile.username = username
            userProfile.productiveHours = productiveHours
            userProfile.points = points
            if let bestFocusTime = bestFocusTime {
                userProfile.bestFocusTime = bestFocusTime
            }
            userProfile.needsSync = true

            updatePublishedProfile(userProfile)

            Task {
                do {
                    try await userProfileManager.saveProfile(userProfile)
                } catch {
                    self.error =
                        "Failed to save profile: \(error.localizedDescription)"
                }
            }
        } catch {
            self.error =
                "Failed to fetch latest profile: \(error.localizedDescription)"
        }
    }

    // CRUD Goal
    @MainActor
    func fetchGoals() async {
        guard let modelContext = modelContext,
            isSignedInToiCloud,
            networkMonitor.isConnected
        else {
            return
        }

        isLoading = true

        do {
            let fetchedGoals = try await goalManager.fetchGoals(
                modelContext: modelContext
            )
            updatePublishedGoals(fetchedGoals)
            await fetchAllTasks()
        } catch {
            self.error = "Failed to fetch goals: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // crud tasks
    @MainActor
    func fetchAllTasks() async {
        guard let modelContext = modelContext,
            isSignedInToiCloud,
            networkMonitor.isConnected
        else {
            return
        }

        do {
            let fetchedTasks = try await taskManager.fetchTasks(
                for: goals,
                modelContext: modelContext
            )
            updatePublishedTasks(fetchedTasks)
        } catch {
            self.error = "Failed to fetch tasks: \(error.localizedDescription)"
        }
    }

    func getTasksForGoal(_ goalId: String) -> [GoalTask] {
        return tasks.filter { $0.goal?.id == goalId }
    }

    // sync
    @MainActor
    func syncPendingItems() async {
        guard let modelContext = modelContext, networkMonitor.isConnected else {
            return
        }

        // Sync deletions
        await goalManager.syncPendingDeletions()
        await taskManager.syncPendingDeletions()

        // Sync profile
        await userProfileManager.syncPendingProfiles(modelContext: modelContext)

        // Sync goals
        await goalManager.syncPendingGoals(modelContext: modelContext)

        // Sync tasks
        await taskManager.syncPendingTasks(modelContext: modelContext)
    }

    var completedTasks: Int {
        return tasks.filter { task in
            task.isCompleted
        }.count
    }

    func startEditingUsername() {
        tempUsername = username
        isEditingName = true
    }

    func saveUsername() {
        guard !tempUsername.trimmingCharacters(in: .whitespaces).isEmpty else {
            tempUsername = username
            isEditingName = false
            errorMessage = "Username cannot be empty."
            print(errorMessage)
            return
        }
        
        guard tempUsername.count >= 2 else {
            tempUsername = username
            isEditingName = false
            errorMessage = "Username must be at least 2 characters long."
            print(errorMessage)
            return
        }
        
        guard tempUsername.count <= 16 else {
            tempUsername = username
            isEditingName = false
            errorMessage = "Username cannot exceed 16 characters."
            print(errorMessage)
            return
        }
        
        errorMessage = ""
        username = tempUsername
        saveUserProfile(
            username: username,
            productiveHours: productiveHours,
            points: points
        )
        isEditingName = false
    }

}
