//
//  OnboardingViewModel.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import Combine
import Foundation
import SwiftData

class OnboardingViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var points: Int = 0
    @Published var productiveHours: [ProductiveHours] = DayOfWeek.allCases.map {
        ProductiveHours(day: $0)
    }
    @Published var isLoading = false
    @Published var error: String = ""

    private var userProfile: UserProfile?
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    private let networkMonitor: NetworkMonitor
    private let userProfileManager: UserProfileManager

    var isSignedInToiCloud: Bool {
        CloudKitManager.shared.isSignedInToiCloud
    }

    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.userProfileManager = UserProfileManager(
            networkMonitor: networkMonitor
        )
        
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
        points: Int
    ) {
        guard let modelContext = modelContext else { return }

        // Update or create profile
        if let existingProfile = userProfile {
            existingProfile.username = username
            existingProfile.productiveHours = productiveHours
            existingProfile.points = points
            existingProfile.needsSync = true
            updatePublishedProfile(existingProfile)
        } else {
            // Create new profile if it doesn't exist
            let userID = UUID().uuidString
            let newProfile = UserProfile(
                id: userID,
                username: username,
                points: points,
                productiveHours: productiveHours,
                needsSync: true
            )
            modelContext.insert(newProfile)
            self.userProfile = newProfile
            updatePublishedProfile(newProfile)
        }

        // save locally
        do {
            try modelContext.save()
        } catch {
            self.error =
                "Failed to save profile locally: \(error.localizedDescription)"
        }

        // Sync to CloudKit if connected
        if networkMonitor.isConnected, isSignedInToiCloud {
            Task {
                do {
                    if let profile = userProfile {
                        try await userProfileManager.saveProfile(profile)
                    }
                } catch {
                    self.error =
                        "Failed to sync profile to iCloud: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // sync
    @MainActor
    func syncPendingItems() async {
        guard let modelContext = modelContext, networkMonitor.isConnected else {
            return
        }

        // Sync profile
        await userProfileManager.syncPendingProfiles(modelContext: modelContext)
    }
}
