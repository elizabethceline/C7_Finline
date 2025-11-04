//
//  ShopTestView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 04/11/25.
//

import SwiftUI
import SwiftData

struct ShopTestView: View {
    @StateObject private var shopVM = ShopViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Shop")
                    .font(.largeTitle)
                    .bold()

                List {
                    Section("Available Items") {
                        ForEach(ShopItem.allCases, id: \.self) { item in
                            HStack {
                                Text(item.displayName)
                                Spacer()
                                Text("\(item.price) points")
                                Button("Buy") {
                                    shopVM.buyItem(item, modelContext: modelContext)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    Section("Purchased Items") {
                        ForEach(shopVM.purchasedItems, id: \.id) { item in
                            HStack {
                                Text(item.shopItem?.displayName ?? item.itemName)
                                Spacer()
                                Button(item.isSelected ? "Selected" : "Select") {
                                    shopVM.toggleSelection(item: item)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await shopVM.fetchPurchasedItems(modelContext: modelContext)
                }
            }
        }
    }
}
