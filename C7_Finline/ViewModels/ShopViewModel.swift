//
//  AITaskGeneratorViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 5/11/25.
//

import Foundation
import SwiftData
import CloudKit
import Combine
import SwiftUI

@MainActor
class ShopViewModel: ObservableObject {
    @Published var coins: Int = 0
    @Published var purchasedItems: [PurchasedItem] = []
    @Published var selectedItem: ShopItem? = nil
    @Published var selectedImage: Image? = nil
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""

    var onSelectedItemChanged: ((ShopItem?) -> Void)?

    private let userProfileManager: UserProfileManager
    private let shopManager: ShopManager
    private var modelContext: ModelContext?
    private var userProfile: UserProfile?

    private var cancellables = Set<AnyCancellable>()

    init(userProfileManager: UserProfileManager, networkMonitor: NetworkMonitor) {
        self.userProfileManager = userProfileManager
        self.shopManager = ShopManager(networkMonitor: networkMonitor)
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func loadLocalData() {
        guard let context = modelContext else { return }

        // Langsung baca data lokal
        if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            self.userProfile = profile
            self.coins = profile.points
        }

        if let items = try? context.fetch(FetchDescriptor<PurchasedItem>()) {
            self.purchasedItems = items
            if let selected = items.first(where: { $0.isSelected }),
               let shopItem = ShopItem(rawValue: selected.itemName) {
                self.selectedItem = shopItem
                self.selectedImage = shopItem.image
            } else {
                self.selectedItem = nil
                self.selectedImage = nil
            }
            self.onSelectedItemChanged?(self.selectedItem)
        }
    }

    func fetchUserProfile(userRecordID: CKRecord.ID) async {
        guard let context = modelContext else { return }

        // Tampilkan local data dulu agar UI cepat
        loadLocalData()

        // Kemudian fetch remote (CloudKit) di background
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await userProfileManager.fetchProfile(
                userRecordID: userRecordID,
                modelContext: context
            )
            self.userProfile = profile
            self.coins = profile.points

            // After profile fetched, fetch purchased items
            let items = try await shopManager.fetchPurchasedItems(modelContext: context)
            self.purchasedItems = items
            if let selected = items.first(where: { $0.isSelected }),
               let shopItem = ShopItem(rawValue: selected.itemName) {
                self.selectedItem = shopItem
                self.selectedImage = shopItem.image
            } else {
                self.selectedItem = nil
                self.selectedImage = nil
            }
            self.onSelectedItemChanged?(self.selectedItem)

        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func buyItem(_ item: ShopItem) async {
        guard let profile = userProfile, let context = modelContext else { return }

        if profile.points < item.price {
            alertMessage = "Not enough points to buy \(item.displayName)."
            return
        }

        profile.points -= item.price
        coins = profile.points

        do {
            try await userProfileManager.saveProfile(profile)
            let purchased = try await shopManager.purchaseItem(item, modelContext: context)
            // Update lokal segera
            self.purchasedItems = try await shopManager.fetchPurchasedItems(modelContext: context)
            self.selectedItem = purchased.shopItem
            self.selectedImage = purchased.shopItem?.image
            self.onSelectedItemChanged?(self.selectedItem)
            alertMessage = "Successfully bought \(item.displayName) for \(item.price) points."
        } catch {
            alertMessage = "Failed to buy item: \(error.localizedDescription)"
        }
    }

    func selectPurchasedItem(_ purchased: PurchasedItem) async {
        guard let context = modelContext else { return }
        await shopManager.selectItem(purchased, modelContext: context)
        if let items: [PurchasedItem] = try? context.fetch(FetchDescriptor<PurchasedItem>()) {
            purchasedItems = items
        } else {
            purchasedItems = []
        }
        if let shopItem = purchased.shopItem {
            selectedItem = shopItem
            selectedImage = shopItem.image
        } else {
            selectedItem = nil
            selectedImage = nil
        }
        onSelectedItemChanged?(selectedItem)
    }

    func deleteAllPurchasedItems() async {
        guard let context = modelContext else { return }
        do {
            let allItems: [PurchasedItem] = try context.fetch(FetchDescriptor<PurchasedItem>())
            for item in allItems {
                context.delete(item)
            }
            try context.save()
            purchasedItems.removeAll()
            selectedItem = nil
            selectedImage = nil
            onSelectedItemChanged?(nil)
        } catch {
            alertMessage = "Failed to delete items: \(error.localizedDescription)"
        }
    }

    func addCoins(_ amount: Int) async {
        guard let profile = userProfile else { return }
        profile.points += amount
        coins = profile.points

        do {
            try await userProfileManager.saveProfile(profile)
            alertMessage = "Added \(amount) points successfully!"
        } catch {
            alertMessage = "Failed to add points: \(error.localizedDescription)"
        }
    }
}
