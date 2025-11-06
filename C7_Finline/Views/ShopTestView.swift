//
//  ShopView.swift
//  C7_Finline
//
//  Created by ChatGPT on 05/11/25.
//

import SwiftUI
import SwiftData

struct ShopTestView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ShopTestViewModel

    init(networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: ShopTestViewModel(
                shopManager: ShopManager(networkMonitor: networkMonitor),
                modelContext: modelContext
            )
        )
    }

    var body: some View {
        VStack {
            Text("🛒 Shop")
                .font(.largeTitle)
                .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.allItems, id: \.rawValue) { item in
                        VStack {
                            item.image
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())

                            Text(item.displayName)
                                .font(.headline)

                            if viewModel.isOwned(item) {
                                Text("Owned ✅")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Button("Buy for \(item.price) coins") {
                                    viewModel.buy(item)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    }
                }
            }

            Divider().padding()

            Text("🎒 Your Items")
                .font(.title2)

            ScrollView {
                ForEach(viewModel.ownedItems, id: \.id) { owned in
                    HStack {
                        if let shopItem = owned.shopItem {
                            shopItem.image
                                .resizable()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            Text(shopItem.displayName)
                        }

                        Spacer()

                        if owned.isSelected {
                            Text("Selected ✅")
                        } else {
                            Button("Select") {
                                viewModel.select(owned)
                            }
                        }
                    }
                    .padding()
                }
            }

            Spacer()
        }
        .padding()
    }
}
