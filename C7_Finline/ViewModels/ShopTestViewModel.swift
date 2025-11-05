//
//  ShopViewModel.swift
//  C7_Finline
//
//  Created by ChatGPT on 05/11/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class ShopTestViewModel: ObservableObject {
    @Published var ownedItems: [PurchasedItem] = []
    @Published var allItems: [ShopItem] = ShopItem.allCases
    @Published var selectedItem: PurchasedItem?
    private var userProfile: UserProfile?

    private let shopManager: ShopManager
    private let modelContext: ModelContext

    init(shopManager: ShopManager, modelContext: ModelContext) {
        self.shopManager = shopManager
        self.modelContext = modelContext
        Task {
            await fetchOwnedItems()
        }
    }

    func fetchOwnedItems() async {
        do {
            let items = try await shopManager.fetchPurchasedItems(modelContext: modelContext)
            ownedItems = items
            selectedItem = items.first(where: { $0.isSelected })
        } catch {
            print("Failed to fetch purchased items: \(error.localizedDescription)")
        }
    }

    func buy(_ item: ShopItem) {
        let newItem = shopManager.purchaseItem(item, modelContext: modelContext)
        ownedItems.append(newItem)
    }

    func select(_ item: PurchasedItem) {
        shopManager.selectItem(item, modelContext: modelContext)
        selectedItem = item
    }

    func isOwned(_ item: ShopItem) -> Bool {
        ownedItems.contains(where: { $0.itemName == item.rawValue })
    }
}
