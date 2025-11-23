//
//  ShopManager.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 11/6/25.
//

import CloudKit
import Foundation
import SwiftData

class ShopManager {
    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor
    private let pendingDeletionKey = "pendingShopDeletionIDs"

    // queue for sync operation
    private let syncQueue = DispatchQueue(
        label: "com.finline.shop.sync",
        qos: .userInitiated
    )
    private let activeTasks = ActiveSyncTasks()

    actor ActiveSyncTasks {
        private var storage: [String: Task<Void, Never>] = [:]

        func get(_ id: String) -> Task<Void, Never>? {
            return storage[id]
        }

        func set(_ id: String, task: Task<Void, Never>) {
            storage[id] = task
        }

        func cancel(_ id: String) {
            if let task = storage[id] {
                task.cancel()
                storage.removeValue(forKey: id)
            }
        }

        func cancelAll(for items: [PurchasedItem]) {
            for item in items {
                if let task = storage[item.id] {
                    task.cancel()
                    storage.removeValue(forKey: item.id)
                }
            }
        }

        func remove(_ id: String) {
            storage.removeValue(forKey: id)
        }
    }

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }

    func fetchPurchasedItems(modelContext: ModelContext) async throws
        -> [PurchasedItem]
    {
        let allLocal = try modelContext.fetch(FetchDescriptor<PurchasedItem>())

        // sync with cloud
        if networkMonitor.isConnected {
            Task {
                do {
                    _ = try await fetchPurchasedItemsFromCloud(
                        modelContext: modelContext
                    )
                } catch {
                    print(
                        "Background sync failed: \(error.localizedDescription)"
                    )
                }
            }
        }

        return allLocal
    }

    func purchaseItem(_ item: ShopItem, modelContext: ModelContext) async throws
        -> PurchasedItem
    {
        if let existing = try modelContext.fetch(
            FetchDescriptor<PurchasedItem>(
                predicate: #Predicate { $0.itemName == item.rawValue }
            )
        ).first {
            return existing
        }

        if let all = try? modelContext.fetch(FetchDescriptor<PurchasedItem>()) {
            for i in all {
                if i.isSelected {
                    i.isSelected = false
                    i.needsSync = true
                }
            }
        }

        let purchased = PurchasedItem(
            id: UUID().uuidString,
            itemName: item.rawValue,
            isSelected: true,
            needsSync: true
        )
        modelContext.insert(purchased)
        try modelContext.save()

        if networkMonitor.isConnected {
            Task {
                await self.syncPurchasedItem(purchased)
            }
        }

        return purchased
    }

    func selectItem(_ item: PurchasedItem, modelContext: ModelContext) async {
        let allItems =
            (try? modelContext.fetch(FetchDescriptor<PurchasedItem>())) ?? []
        for i in allItems {
            let wasSelected = i.isSelected
            i.isSelected = (i.id == item.id)
            if wasSelected != i.isSelected {
                i.needsSync = true
            }
        }

        try? modelContext.save()

        cancelExistingSyncTasks(for: allItems)

        if networkMonitor.isConnected {
            for i in allItems where i.needsSync {
                scheduleSyncTask(for: i)
            }
        }
    }

    func deleteItem(_ item: PurchasedItem, modelContext: ModelContext) {
        let itemIDToDelete = item.id

        modelContext.delete(item)
        addPendingDeletionID(itemIDToDelete)

        if networkMonitor.isConnected {
            Task {
                await syncPendingDeletions()
            }
        }
    }

    func syncPurchasedItem(_ item: PurchasedItem) async {
        guard networkMonitor.isConnected else {
            item.needsSync = true
            return
        }

        if getPendingDeletionIDs().contains(item.id) {
            return
        }

        let recordID = CKRecord.ID(recordName: item.id)
        do {
            let record: CKRecord
            do {
                record = try await cloudKit.fetchRecord(recordID: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                record = CKRecord(
                    recordType: "PurchasedItems",
                    recordID: recordID
                )
            }
            record["itemName"] = item.itemName as CKRecordValue
            record["isSelected"] = (item.isSelected ? 1 : 0) as CKRecordValue

            _ = try await cloudKit.saveRecord(record)

            await MainActor.run {
                item.needsSync = false
            }

        } catch let error as CKError {
            switch error.code {
            case .serverRecordChanged:
                print(
                    "Record conflict for item \(item.itemName) - will retry on next sync"
                )

            case .networkUnavailable, .networkFailure:
                print(
                    "Network error syncing item \(item.itemName) - will retry later"
                )

            default:
                print(
                    "Failed to sync purchased item: \(error.localizedDescription)"
                )
            }
        } catch {
            print(
                "Failed to sync purchased item: \(error.localizedDescription)"
            )
        }
    }

    func fetchPurchasedItemsFromCloud(modelContext: ModelContext) async throws
        -> [PurchasedItem]
    {
        guard networkMonitor.isConnected else {
            return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
        }

        let query = CKQuery(
            recordType: "PurchasedItems",
            predicate: NSPredicate(value: true)
        )
        let records = try await cloudKit.fetchRecords(query: query)
        let cloudRecordIDs = Set(records.map { $0.recordID.recordName })

        for record in records {
            let itemId = record.recordID.recordName
            let itemName = record["itemName"] as? String ?? ""
            let isSelected = (record["isSelected"] as? Int) == 1

            let existing = try? modelContext.fetch(
                FetchDescriptor<PurchasedItem>(
                    predicate: #Predicate { $0.id == itemId }
                )
            ).first

            if let existing = existing {
                if !existing.needsSync {
                    existing.itemName = itemName
                    existing.isSelected = isSelected
                }
            } else {
                let newItem = PurchasedItem(
                    id: itemId,
                    itemName: itemName,
                    isSelected: isSelected,
                    needsSync: false
                )
                modelContext.insert(newItem)
            }
        }

        let allLocalItems = try modelContext.fetch(
            FetchDescriptor<PurchasedItem>()
        )
        let itemsToDelete = allLocalItems.filter {
            !cloudRecordIDs.contains($0.id) && !$0.needsSync
        }

        for item in itemsToDelete {
            modelContext.delete(item)
        }

        try modelContext.save()
        return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
    }

    func syncPendingItems(modelContext: ModelContext) async {
        guard networkMonitor.isConnected else { return }

        let itemPredicate = #Predicate<PurchasedItem> { $0.needsSync == true }
        let pendingDeletionIDs = getPendingDeletionIDs()

        guard
            let itemsToSync = try? modelContext.fetch(
                FetchDescriptor(predicate: itemPredicate)
            )
        else { return }

        let filteredItems = itemsToSync.filter {
            !pendingDeletionIDs.contains($0.id)
        }

        for item in filteredItems {
            await syncPurchasedItem(item)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    func syncPendingDeletions() async {
        guard networkMonitor.isConnected else { return }

        let idsToDelete = getPendingDeletionIDs()

        for id in idsToDelete {
            let recordID = CKRecord.ID(recordName: id)
            do {
                try await cloudKit.deleteRecord(recordID: recordID)
                removePendingDeletionID(id)
            } catch let error as CKError where error.code == .unknownItem {
                removePendingDeletionID(id)
            } catch {
                print(
                    "Failed to delete purchased item \(id): \(error.localizedDescription)"
                )
            }
        }
    }

    private func getPendingDeletionIDs() -> Set<String> {
        let array =
            UserDefaults.standard.stringArray(forKey: pendingDeletionKey) ?? []
        return Set(array)
    }

    private func savePendingDeletionIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: pendingDeletionKey)
    }

    private func addPendingDeletionID(_ id: String) {
        var currentIDs = getPendingDeletionIDs()
        currentIDs.insert(id)
        savePendingDeletionIDs(currentIDs)
    }

    private func removePendingDeletionID(_ id: String) {
        var currentIDs = getPendingDeletionIDs()
        if currentIDs.remove(id) != nil {
            savePendingDeletionIDs(currentIDs)
        }
    }

    private func scheduleSyncTask(for item: PurchasedItem) {
        Task {
            await activeTasks.cancel(item.id)

            let task = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)

                guard !Task.isCancelled else { return }

                await syncPurchasedItem(item)

                await activeTasks.remove(item.id)
            }

            await activeTasks.set(item.id, task: task)
        }
    }

    private func cancelExistingSyncTasks(for items: [PurchasedItem]) {
        Task {
            await activeTasks.cancelAll(for: items)
        }
    }
}
