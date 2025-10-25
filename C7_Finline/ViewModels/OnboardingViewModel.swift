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
            Task { await syncPendingItems() }
        }

        Task {
            await checkiCloud()
        }
    }

    @MainActor
    private func checkiCloud() async {
        isLoading = true
        defer { isLoading = false }

        var retries = 0
        while !isSignedInToiCloud && retries < 10 {
            print("Waiting for iCloud sign-in (\(retries + 1))...")
            try? await Task.sleep(nanoseconds: 500_000_000)
            retries += 1
        }

        if isSignedInToiCloud {
            print("iCloud signed in, fetching profile…")
            await fetchUserProfile()
        } else {
            print("Still not signed in to iCloud after waiting.")
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
        username = profile?.username ?? ""
        points = profile?.points ?? 0
        productiveHours =
            profile?.productiveHours
            ?? DayOfWeek.allCases.map {
                ProductiveHours(day: $0)
            }

        print("Updated published profile: \(String(describing: profile))")
    }

    // fetch + create/update user profile
    @MainActor
    func fetchUserProfile() async {
        guard let modelContext, isSignedInToiCloud else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let userRecordID = try await CloudKitManager.shared
                .fetchUserRecordID()
            print("recordID: \(userRecordID)")

            let profile = try await userProfileManager.fetchProfile(
                userRecordID: userRecordID,
                modelContext: modelContext
            )

            print("userProfile from iCloud: \(profile)")
            updatePublishedProfile(profile)
        } catch {
            self.error =
                "Failed to fetch user profile: \(error.localizedDescription)"
            print("fetchUserProfile error: \(error)")
        }
    }

    @MainActor
    func saveUserProfile(
        username: String,
        productiveHours: [ProductiveHours],
        points: Int
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

    // sync
    @MainActor
    func syncPendingItems() async {
        guard let modelContext, networkMonitor.isConnected else { return }
        await userProfileManager.syncPendingProfiles(modelContext: modelContext)
    }
}
