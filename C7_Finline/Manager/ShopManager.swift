//
//  ShopManager.swift
//  C7_Finline
//

import Foundation
import SwiftData
import CloudKit

class ShopManager {
    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor
    private let pendingDeletionKey = "pendingPurchasedItemDeletionIDs"

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }

    // Fetch purchased items
    func fetchPurchasedItems(modelContext: ModelContext) async throws -> [PurchasedItem] {
        guard networkMonitor.isConnected else {
            return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
        }

        let query = CKQuery(recordType: "PurchasedItems", predicate: NSPredicate(value: true))
        let records = try await cloudKit.fetchRecords(query: query)

        for record in records {
            let item = PurchasedItem(record: record)
            let selectedItem = item.id
            if let existing = try? modelContext.fetch(
                FetchDescriptor<PurchasedItem>(predicate: #Predicate<PurchasedItem> { $0.id == selectedItem })
            ).first {
                existing.isSelected = item.isSelected
                existing.needsSync = false
            } else {
                modelContext.insert(item)
            }
        }

        try? modelContext.save()
        return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
    }

    // Buy item
    func buyItem(_ shopItem: ShopItem, modelContext: ModelContext) {
        let newItem = PurchasedItem(
            id: UUID().uuidString,
            itemName: shopItem.rawValue,
            isSelected: false,
            needsSync: true
        )
        modelContext.insert(newItem)

        Task {
            await syncPurchasedItem(newItem)
        }
    }

    // Toggle selection
    func toggleSelection(item: PurchasedItem) {
        item.isSelected.toggle()
        item.needsSync = true
        Task {
            await syncPurchasedItem(item)
        }
    }

    // Sync single item
    func syncPurchasedItem(_ item: PurchasedItem) async {
        guard networkMonitor.isConnected else { return }

        let recordID = CKRecord.ID(recordName: item.id)
        let record: CKRecord

        do {
            record = try await cloudKit.fetchRecord(recordID: recordID)
        } catch {
            record = CKRecord(recordType: "PurchasedItems", recordID: recordID)
        }

        record["itemName"] = item.itemName as CKRecordValue
        record["isSelected"] = (item.isSelected ? 1 : 0) as CKRecordValue

        do {
            _ = try await cloudKit.saveRecord(record)
            await MainActor.run {
                item.needsSync = false
            }
        } catch {
            print("Failed to sync purchased item \(item.itemName): \(error.localizedDescription)")
        }
    }

    // Delete purchased item
    func deletePurchasedItem(_ item: PurchasedItem, modelContext: ModelContext) {
        modelContext.delete(item)
        addPendingDeletionID(item.id)
        Task {
            await syncPendingDeletions()
        }
    }

    // Pending deletions
    private func getPendingDeletionIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: pendingDeletionKey) ?? [])
    }

    private func savePendingDeletionIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: pendingDeletionKey)
    }

    private func addPendingDeletionID(_ id: String) {
        var ids = getPendingDeletionIDs()
        ids.insert(id)
        savePendingDeletionIDs(ids)
    }

    private func removePendingDeletionID(_ id: String) {
        var ids = getPendingDeletionIDs()
        ids.remove(id)
        savePendingDeletionIDs(ids)
    }

    func syncPendingDeletions() async {
        guard networkMonitor.isConnected else { return }

        for id in getPendingDeletionIDs() {
            let recordID = CKRecord.ID(recordName: id)
            do {
                try await cloudKit.deleteRecord(recordID: recordID)
                removePendingDeletionID(id)
            } catch {
                print("Failed to delete purchased item \(id): \(error.localizedDescription)")
            }
        }
    }
}
