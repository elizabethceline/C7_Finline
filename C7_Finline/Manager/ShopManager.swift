//
//  ShopManager.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 11/6/25.
//

import Foundation
import SwiftData
import CloudKit

class ShopManager {
    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }

    func fetchPurchasedItems(modelContext: ModelContext) async throws -> [PurchasedItem] {
        let allLocal = try modelContext.fetch(FetchDescriptor<PurchasedItem>())
        return allLocal
    }

    func purchaseItem(_ item: ShopItem, modelContext: ModelContext) async throws -> PurchasedItem {
        if let existing = try modelContext.fetch(
            FetchDescriptor<PurchasedItem>(predicate: #Predicate { $0.itemName == item.rawValue })
        ).first {
            return existing
        }

        if let all = try? modelContext.fetch(FetchDescriptor<PurchasedItem>()) {
            for i in all {
                i.isSelected = false
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

        Task { await self.syncPurchasedItem(purchased) }

        return purchased
    }

    func selectItem(_ item: PurchasedItem, modelContext: ModelContext) async {
        if let all = try? modelContext.fetch(FetchDescriptor<PurchasedItem>()) {
            for i in all {
                i.isSelected = false
            }
        }
        item.isSelected = true
        item.needsSync = true
        try? modelContext.save()

        Task { await self.syncPurchasedItem(item) }
    }

    func syncPurchasedItem(_ item: PurchasedItem) async {
        guard networkMonitor.isConnected else {
            return
        }

        let recordID = CKRecord.ID(recordName: item.id)
        do {
            let record: CKRecord
            do {
                record = try await cloudKit.fetchRecord(recordID: recordID)
            } catch {
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
    
    func fetchPurchasedItemsFromCloud(modelContext: ModelContext) async throws -> [PurchasedItem] {
        guard networkMonitor.isConnected else {
            return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
        }
        
        let query = CKQuery(recordType: "PurchasedItems", predicate: NSPredicate(value: true))
        let records = try await cloudKit.fetchRecords(query: query)
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
                existing.itemName = itemName
                existing.isSelected = isSelected
                existing.needsSync = false
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
        
        try modelContext.save()
        return try modelContext.fetch(FetchDescriptor<PurchasedItem>())
    }
    
    
}
