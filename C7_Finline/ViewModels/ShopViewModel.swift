//
//  AITaskGeneratorViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 5/11/25.
//

import CloudKit
import Combine
import Foundation
import SwiftData
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
    private let networkMonitor: NetworkMonitor
    private var modelContext: ModelContext?
    private var userProfile: UserProfile?

    private var cancellables = Set<AnyCancellable>()
    private var syncDebounceTask: Task<Void, Never>?

    init(userProfileManager: UserProfileManager, networkMonitor: NetworkMonitor)
    {
        self.userProfileManager = userProfileManager
        self.networkMonitor = networkMonitor
        self.shopManager = ShopManager(networkMonitor: networkMonitor)

        observeNetworkStatus()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    private func observeNetworkStatus() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)  // Debounce network changes
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    self.syncDebounceTask?.cancel()

                    // Schedule new sync with delay
                    self.syncDebounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        guard !Task.isCancelled else { return }
                        await self.syncPendingItems()
                    }
                }
            }
            .store(in: &cancellables)
    }

    func loadLocalData() {
        guard let context = modelContext else { return }

        // Langsung baca data lokal
        if let profile = try? context.fetch(FetchDescriptor<UserProfile>())
            .first
        {
            self.userProfile = profile
            self.coins = profile.points
        }

        if let items = try? context.fetch(FetchDescriptor<PurchasedItem>()) {
            self.purchasedItems = items
            updateSelectedItem(from: items)
        }
    }

    func fetchUserProfile(userRecordID: CKRecord.ID) async {
        guard let context = modelContext else { return }

        loadLocalData()

        guard networkMonitor.isConnected else {
            print("Offline mode: Using local data")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await userProfileManager.fetchProfile(
                userRecordID: userRecordID,
                modelContext: context
            )
            self.userProfile = profile
            self.coins = profile.points

            let items = try await shopManager.fetchPurchasedItemsFromCloud(
                modelContext: context
            )
            self.purchasedItems = items
            updateSelectedItem(from: items)

        } catch {
            alertMessage = "Failed to sync: \(error.localizedDescription)"
            print("Cloud sync error: \(error)")
        }
    }

    func buyItem(_ item: ShopItem) async {
        guard let profile = userProfile, let context = modelContext else {
            return
        }

        if profile.points < item.price {
            alertMessage = "Not enough points to buy \(item.displayName)."
            return
        }

        profile.points -= item.price
        coins = profile.points

        do {
            try await userProfileManager.saveProfile(profile)
            let purchased = try await shopManager.purchaseItem(
                item,
                modelContext: context
            )
            // Update lokal segera
            self.purchasedItems = try await shopManager.fetchPurchasedItems(
                modelContext: context
            )
            self.selectedItem = purchased.shopItem
            self.selectedImage = purchased.shopItem?.image
            self.onSelectedItemChanged?(self.selectedItem)

            if networkMonitor.isConnected {
                alertMessage =
                    "Successfully bought \(item.displayName) for \(item.price) points."
            } else {
                alertMessage =
                    "Successfully bought \(item.displayName) for \(item.price) points. Will sync when online."
            }
        } catch {
            profile.points += item.price
            coins = profile.points
            alertMessage = "Failed to buy item: \(error.localizedDescription)"
        }
    }

    func selectPurchasedItem(_ purchased: PurchasedItem) async {
        guard let context = modelContext else { return }
        await shopManager.selectItem(purchased, modelContext: context)
        if let items: [PurchasedItem] = try? context.fetch(
            FetchDescriptor<PurchasedItem>()
        ) {
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

    // Sync pending items (called when network reconnects)
    private func syncPendingItems() async {
        guard let context = modelContext, networkMonitor.isConnected else {
            return
        }

        print("Syncing pending shop items...")

        // Sync pending deletions
        await shopManager.syncPendingDeletions()

        // Sync pending items
        await shopManager.syncPendingItems(modelContext: context)

        // Refresh local data
        loadLocalData()
    }

    private func updateSelectedItem(from items: [PurchasedItem]) {
        if let selected = items.first(where: { $0.isSelected }),
            let shopItem = ShopItem(rawValue: selected.itemName)
        {
            self.selectedItem = shopItem
            self.selectedImage = shopItem.image
        } else {
            self.selectedItem = nil
            self.selectedImage = nil
        }
        self.onSelectedItemChanged?(self.selectedItem)
    }

    func deleteAllPurchasedItems() async {
        guard let context = modelContext else { return }
        do {
            let allItems: [PurchasedItem] = try context.fetch(
                FetchDescriptor<PurchasedItem>()
            )
            for item in allItems {
                context.delete(item)
            }
            try context.save()
            purchasedItems.removeAll()
            selectedItem = nil
            selectedImage = nil
            onSelectedItemChanged?(nil)
        } catch {
            alertMessage =
                "Failed to delete items: \(error.localizedDescription)"
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
