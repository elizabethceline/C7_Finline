//
//  ProfileViewModel.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import CloudKit
import Combine
import Foundation
import SwiftData

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
    @Published var shopVM: ShopViewModel?

    @Published var isEditingName = false
    @Published var tempUsername = ""

    private var userProfile: UserProfile?
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    private var lastSaveTime: Date = .distantPast

    private let networkMonitor: NetworkMonitor
    private let userProfileManager: UserProfileManager
    private let goalManager: GoalManager
    private let taskManager: TaskManager

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

    @MainActor
    func initializeShopVM() {
        guard let context = modelContext else { return }

        let shopVM = ShopViewModel(
            userProfileManager: self.userProfileManagerInstance,
            networkMonitor: self.networkMonitorInstance
        )
        shopVM.setModelContext(context)
        self.shopVM = shopVM

        shopVM.onSelectedItemChanged = { [weak self] newItem in
            guard let self else { return }
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }

        Task {
            if let userRecordID = await self.userRecordID {
                await shopVM.fetchUserProfile(userRecordID: userRecordID)
            }
        }
    }

    var errorMessage = ""

    var isSignedInToiCloud: Bool {
        CloudKitManager.shared.isSignedInToiCloud
    }

    init(networkMonitor: NetworkMonitor = .shared) {
        self.networkMonitor = networkMonitor
        self.userProfileManager = UserProfileManager(
            networkMonitor: networkMonitor
        )
        self.goalManager = GoalManager(networkMonitor: networkMonitor)
        self.taskManager = TaskManager(networkMonitor: networkMonitor)

        observeNetworkStatus()
        setupSyncObservers()
    }

    private func setupSyncObservers() {
        NotificationCenter.default.publisher(
            for: Notification.Name("ProfileDataDidSync")
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            print("ProfileViewModel: Background Sync Received.")
            Task { @MainActor in
                self?.forceLoadData()
            }
        }
        .store(in: &cancellables)
    }

    @MainActor
    func setModelContext(_ context: ModelContext) {
        let isFirstSetup = (self.modelContext == nil)

        if self.modelContext == nil {
            self.modelContext = context
        }

        loadDataFromSwiftData()

        if networkMonitor.isConnected {
            Task {
                await syncPendingItems()
            }
        }

        if isFirstSetup || userProfile == nil {
            fetchUserProfile()
        }

        if isFirstSetup {
            Task {
                await initializeShopVM()
            }
        }
    }

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

    @MainActor
    private func forceLoadData() {
        performLoadData()
    }

    @MainActor
    private func loadDataFromSwiftData() {
        let timeSinceLastSave = Date().timeIntervalSince(lastSaveTime)
        if timeSinceLastSave < 2.0 {
            print(
                "Skipping disk load (Recent save detected: \(timeSinceLastSave)s ago)"
            )
            return
        }

        performLoadData()
    }

    @MainActor
    private func performLoadData() {
        guard let modelContext = modelContext else { return }

        do {
            let profileDescriptor = FetchDescriptor<UserProfile>()
            if let profile = try modelContext.fetch(profileDescriptor).first {
                updatePublishedProfile(profile)
            }

            let goalDescriptor = FetchDescriptor<Goal>(
                sortBy: [SortDescriptor(\.due, order: .forward)]
            )
            let goals = try modelContext.fetch(goalDescriptor)
            updatePublishedGoals(goals)

            let taskDescriptor = FetchDescriptor<GoalTask>()
            let tasks = try modelContext.fetch(taskDescriptor)
            updatePublishedTasks(tasks)

            print("Data loaded from SwiftData")
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
        Task { @MainActor in
            guard let modelContext = self.modelContext else { return }

            self.lastSaveTime = Date()

            do {
                let descriptor = FetchDescriptor<UserProfile>()
                let currentProfile =
                    try modelContext.fetch(descriptor).first ?? self.userProfile

                let userProfile: UserProfile
                if let existing = currentProfile {
                    userProfile = existing
                } else {
                    // Create new profile if none exists
                    let userRecordID: String
                    if self.isSignedInToiCloud {
                        do {
                            let recordID = try await CloudKitManager.shared
                                .fetchUserRecordID()
                            userRecordID = recordID.recordName
                        } catch {
                            userRecordID = UUID().uuidString
                        }
                    } else {
                        // Generate a local ID when not connected to iCloud
                        userRecordID = UUID().uuidString
                    }

                    let newProfile = UserProfile(
                        id: userRecordID,
                        username: "",
                        points: 0,
                        productiveHours: DayOfWeek.allCases.map {
                            ProductiveHours(day: $0)
                        },
                        bestFocusTime: 0,
                        needsSync: true
                    )
                    modelContext.insert(newProfile)
                    self.userProfile = newProfile
                    userProfile = newProfile
                }

                userProfile.username = username
                userProfile.productiveHours = productiveHours
                userProfile.points = points
                if let bestFocusTime = bestFocusTime {
                    userProfile.bestFocusTime = bestFocusTime
                }
                userProfile.needsSync = true

                self.updatePublishedProfile(userProfile)

                try modelContext.save()
                print("Profile Saved Locally")

                Task {
                    do {
                        try await self.userProfileManager.saveProfile(
                            userProfile
                        )
                        print("Profile Pushed to Cloud")
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
    }

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

    @MainActor
    func syncPendingItems() async {
        guard let modelContext = modelContext, networkMonitor.isConnected else {
            return
        }

        await goalManager.syncPendingDeletions()
        await taskManager.syncPendingDeletions()

        await userProfileManager.syncPendingProfiles(modelContext: modelContext)

        await goalManager.syncPendingGoals(modelContext: modelContext)

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
            return
        }

        guard tempUsername.count >= 2 else {
            tempUsername = username
            isEditingName = false
            errorMessage = "Username must be at least 2 characters long."
            return
        }

        guard tempUsername.count <= 16 else {
            tempUsername = username
            isEditingName = false
            errorMessage = "Username cannot exceed 16 characters."
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

extension ProfileViewModel {
    @MainActor
    func updateFromProfile(_ profile: UserProfile) {
        self.userProfile = profile
        self.username = profile.username
        self.points = profile.points
        self.productiveHours = profile.productiveHours
        self.bestFocusTime = profile.bestFocusTime
    }
}
