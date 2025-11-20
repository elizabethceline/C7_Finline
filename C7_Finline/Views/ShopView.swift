//
//  ShopView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 03/11/25.
//

import CloudKit
import Combine
import SwiftData
import SwiftUI

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var purchasedItems: [PurchasedItem]

    @StateObject private var viewModel: ShopViewModel

    let userRecordID: CKRecord.ID

    private var currentProfile: UserProfile? { profiles.first }
    private var coins: Int { currentProfile?.points ?? 0 }
    private var selectedItem: ShopItem? {
        purchasedItems.first(where: { $0.isSelected })?.shopItem
    }

    init(userRecordID: CKRecord.ID) {
        self.userRecordID = userRecordID

        let networkMonitor = NetworkMonitor.shared
        let userProfileManager = UserProfileManager(
            networkMonitor: networkMonitor
        )

        _viewModel = StateObject(
            wrappedValue: ShopViewModel(
                userProfileManager: userProfileManager,
                networkMonitor: networkMonitor
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                headerView
                //
                //                HStack(spacing: 12) {
                //                    Button {
                //                        Task { await viewModel.addCoins(100) }
                //                    } label: {
                //                        Label("Add 100 Coins", systemImage: "bitcoinsign.circle.fill")
                //                            .font(.body)
                //                            .fontWeight(.semibold)
                //                            .padding()
                //                            .frame(maxWidth: .infinity)
                //                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.green.opacity(0.2)))
                //                    }
                //
                //                    Button(role: .destructive) {
                //                        Task { await viewModel.deleteAllPurchasedItems() }
                //                    } label: {
                //                        Label("Delete Purchased", systemImage: "trash")
                //                            .font(.body)
                //                            .fontWeight(.semibold)
                //                            .padding()
                //                            .frame(maxWidth: .infinity)
                //                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.2)))
                //                    }
                //                }
                //                .padding(.horizontal)

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ],
                        spacing: 5
                    ) {
                        ForEach(ShopItem.allCases, id: \.rawValue) { item in
                            ShopCardView(
                                item: item,
                                status: status(for: item),
                                price: item.price,
                                onTap: { handleTap(for: item) }
                            )
                            .disabled(
                                viewModel.isPurchasing || viewModel.isLoading
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
                Spacer()
            }
            .task {
                viewModel.setModelContext(modelContext)
                await viewModel.fetchUserProfile(userRecordID: userRecordID)
            }
            .onChange(of: purchasedItems) { _, _ in
                viewModel.objectWillChange.send()
            }
            .onChange(of: currentProfile?.points) { _, _ in
                viewModel.objectWillChange.send()
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert(
                "Notice",
                isPresented: .constant(!viewModel.alertMessage.isEmpty)
            ) {
                Button("OK") { viewModel.alertMessage = "" }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Text("\(coins)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(.yellow)
                    .imageScale(.large)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.primary))
        }
        .padding(.horizontal)
    }

    private func status(for item: ShopItem) -> ShopCardStatus {
        if let purchased = purchasedItems.first(where: {
            $0.itemName == item.rawValue
        }) {
            return purchased.isSelected ? .selected : .choose
        }

        if item.isDefault {
            return .choose
        }

        return .price
    }

    private func handleTap(for item: ShopItem) {
        if viewModel.isPurchasing { return }

        Task {
            if let purchased = purchasedItems.first(where: {
                $0.itemName == item.rawValue
            }) {
                await viewModel.selectPurchasedItem(purchased)
            } else if item.isDefault {
                await viewModel.ensureDefaultCharacterExists()

                try? await Task.sleep(nanoseconds: 100_000_000)
                if let purchased = purchasedItems.first(where: {
                    $0.itemName == item.rawValue
                }) {
                    await viewModel.selectPurchasedItem(purchased)
                }
            } else {
                await viewModel.buyItem(item)
            }
        }
    }
}
