//
//  ShopViewModel.swift
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
        subscribeToSyncNotifications()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadLocalData()
    }

    private func subscribeToSyncNotifications() {
        NotificationCenter.default.publisher(
            for: Notification.Name("ShopDataDidSync")
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.loadLocalData()
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: Notification.Name("ProfileDataDidSync")
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.loadLocalData()
        }
        .store(in: &cancellables)
    }

    private func observeNetworkStatus() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    self.syncDebounceTask?.cancel()
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
            self.purchasedItems = items.sorted(by: { $0.itemName < $1.itemName }
            )
            updateSelectedItem(from: items)
        }
    }

    func fetchUserProfile(userRecordID: CKRecord.ID) async {
        guard let context = modelContext else { return }

        loadLocalData()

        await ensureDefaultCharacter()

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

    private func ensureDefaultCharacter() async {
        guard let context = modelContext else { return }

        do {
            let existingItems = try context.fetch(
                FetchDescriptor<PurchasedItem>()
            )

            // If no items exist, add default character
            if existingItems.isEmpty {
                let defaultItem = PurchasedItem(
                    id: UUID().uuidString,
                    itemName: ShopItem.finley.rawValue,
                    isSelected: true,
                    needsSync: networkMonitor.isConnected
                )
                context.insert(defaultItem)
                try context.save()

                // Sync to cloud if online
                if networkMonitor.isConnected {
                    await shopManager.syncPendingItems(modelContext: context)
                }

                loadLocalData()
            }
        } catch {
            print("Error ensuring default character: \(error)")
        }
    }

    func ensureDefaultCharacterExists() async {
        guard let context = modelContext else { return }

        do {
            let existingItems = try context.fetch(
                FetchDescriptor<PurchasedItem>()
            )

            // Check if default character exists
            let hasDefault = existingItems.contains(where: {
                $0.itemName == ShopItem.finley.rawValue
            })

            if !hasDefault {
                let defaultItem = PurchasedItem(
                    id: UUID().uuidString,
                    itemName: ShopItem.finley.rawValue,
                    isSelected: false,
                    needsSync: networkMonitor.isConnected
                )
                context.insert(defaultItem)
                try context.save()

                // Sync to cloud if online
                if networkMonitor.isConnected {
                    await shopManager.syncPendingItems(modelContext: context)
                }

                loadLocalData()
            }
        } catch {
            print("Error ensuring default character exists: \(error)")
        }
    }

    func buyItem(_ item: ShopItem) async {
        guard let profile = userProfile, let context = modelContext else {
            return
        }

        if item.isDefault {
            alertMessage = "\(item.displayName) is your default character!"
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

            loadLocalData()

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
        loadLocalData()
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

        await MainActor.run {
            loadLocalData()
        }
    }

    private func updateSelectedItem(from items: [PurchasedItem]) {
        if let selected = items.first(where: { $0.isSelected }),
           let shopItem = ShopItem(rawValue: selected.itemName) {
            self.selectedItem = shopItem
            self.selectedImage = shopItem.image
        } else {
            self.selectedItem = .finley
            self.selectedImage = ShopItem.finley.image
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

            await ensureDefaultCharacter()

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
