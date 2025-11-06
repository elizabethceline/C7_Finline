//
//  ShopViewModel.swift
//  C7_Finline
//
//  Created by GPT-5 on 05/11/25.
//

import Foundation
import SwiftData
import CloudKit
import Combine

@MainActor
class ShopViewModel: ObservableObject {
    @Published var coins: Int = 0
    @Published var selectedItem: ShopItem? = nil
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    private let userProfileManager: UserProfileManager
    private let networkMonitor: NetworkMonitor
    private var modelContext: ModelContext?
    private var userProfile: UserProfile?

    init(
        userProfileManager: UserProfileManager,
        networkMonitor: NetworkMonitor
    ) {
        self.userProfileManager = userProfileManager
        self.networkMonitor = networkMonitor
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func fetchUserProfile(userRecordID: CKRecord.ID) async {
        guard let context = modelContext else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await userProfileManager.fetchProfile(
                userRecordID: userRecordID,
                modelContext: context
            )
            self.userProfile = profile
            self.coins = profile.points
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func reduceCoins(by amount: Int) async {
        guard let userProfile = userProfile else { return }
        guard userProfile.points >= amount else {
            await addCoins()
            errorMessage = "Not enough coins!"
            return
        }

        userProfile.points -= amount
        coins = userProfile.points

        do {
            try await userProfileManager.saveProfile(userProfile)
        } catch {
            print("Failed to update coins: \(error.localizedDescription)")
        }
    }
    
    func addCoins(amount: Int = 100) async {
            guard let userProfile = userProfile else {
                errorMessage = "User profile not loaded."
                return
            }

            userProfile.points += amount
            coins = userProfile.points

            do {
                try await userProfileManager.saveProfile(userProfile)
            } catch {
                print("Failed to add coins: \(error.localizedDescription)")
            }
        }
}
