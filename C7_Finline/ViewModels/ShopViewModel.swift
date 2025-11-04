//
//  ShopViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 04/11/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class ShopViewModel: ObservableObject {
    @Published var purchasedItems: [PurchasedItem] = []

    private let networkMonitor = NetworkMonitor()
    private lazy var shopManager = ShopManager(networkMonitor: networkMonitor)

    func fetchPurchasedItems(modelContext: ModelContext) async {
        do {
            purchasedItems = try await shopManager.fetchPurchasedItems(modelContext: modelContext)
        } catch {
            print("Failed to fetch purchased items: \(error)")
        }
    }

    func buyItem(_ shopItem: ShopItem, modelContext: ModelContext) {
        shopManager.buyItem(shopItem, modelContext: modelContext)
        Task {
            await fetchPurchasedItems(modelContext: modelContext)
        }
    }

    func toggleSelection(item: PurchasedItem) {
        shopManager.toggleSelection(item: item)
        purchasedItems = purchasedItems.map { $0.id == item.id ? item : $0 }
    }
}
