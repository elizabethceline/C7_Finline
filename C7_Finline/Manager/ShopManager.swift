//
//  ShopManager.swift
//  C7_Finline
//
//  Created by ChatGPT on 05/11/25.
//

import Foundation
import SwiftData
import CloudKit

class ShopManager {
    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor
    private let pendingDeletionKey = "pendingPurchasedDeletionIDs"

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }

    func fetchPurchasedItems(modelContext: ModelContext) async throws -> [PurchasedItem] {
        guard networkMonitor.isConnected else {
            return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
        }

        let query = CKQuery(recordType: "PurchasedItems", predicate: NSPredicate(value: true))
        let ckRecords = try await cloudKit.fetchRecords(query: query)
        let cloudIDs = Set(ckRecords.map { $0.recordID.recordName })

        for record in ckRecords {
            let purchased = PurchasedItem(record: record)
            let selectedPurchased =  purchased.id
            let predicate = #Predicate<PurchasedItem> { $0.id == selectedPurchased }

            if let existing = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
                existing.itemName = purchased.itemName
                existing.isSelected = purchased.isSelected
                existing.needsSync = false
            } else {
                modelContext.insert(purchased)
            }
        }

        let allLocal = try modelContext.fetch(FetchDescriptor<PurchasedItem>())
        let toDelete = allLocal.filter {
            !cloudIDs.contains($0.id) && !$0.needsSync
        }

        for item in toDelete {
            modelContext.delete(item)
        }

        try? modelContext.save()
        return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
    }

    func purchaseItem(_ item: ShopItem, modelContext: ModelContext) -> PurchasedItem {
        let purchased = PurchasedItem(
            id: UUID().uuidString,
            itemName: item.rawValue,
            isSelected: false,
            needsSync: true
        )

        modelContext.insert(purchased)

        Task {
            await syncPurchasedItem(purchased)
        }

        return purchased
    }

    func selectItem(_ item: PurchasedItem, modelContext: ModelContext) {
        if let all = try? modelContext.fetch(FetchDescriptor<PurchasedItem>()) {
            for i in all {
                i.isSelected = false
            }
        }

        item.isSelected = true
        item.needsSync = true

        Task {
            await syncPurchasedItem(item)
        }
    }

    func syncPurchasedItem(_ item: PurchasedItem) async {
        guard networkMonitor.isConnected else {
            item.needsSync = true
            return
        }

        let recordID = CKRecord.ID(recordName: item.id)

        do {
            let record: CKRecord
            do {
                record = try await cloudKit.fetchRecord(recordID: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                record = CKRecord(recordType: "PurchasedItems", recordID: recordID)
            }

            record["itemName"] = item.itemName as CKRecordValue
            record["isSelected"] = (item.isSelected ? 1 : 0) as CKRecordValue

            _ = try await cloudKit.saveRecord(record)

            await MainActor.run {
                item.needsSync = false
            }
        } catch {
            print("Failed to sync purchased item: \(error.localizedDescription)")
        }
    }

    func syncPendingItems(modelContext: ModelContext) async {
        guard networkMonitor.isConnected else { return }

        let predicate = #Predicate<PurchasedItem> { $0.needsSync == true }
        guard let pending = try? modelContext.fetch(FetchDescriptor(predicate: predicate)) else { return }

        for item in pending {
            await syncPurchasedItem(item)
        }
    }
}
