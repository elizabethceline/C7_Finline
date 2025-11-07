//
//  ShopView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 03/11/25.
//

import SwiftUI
import CloudKit
import SwiftData

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var viewModel: ShopViewModel
    let userRecordID: CKRecord.ID

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
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                        ForEach(ShopItem.allCases, id: \.rawValue) { item in
                            ShopCardView(
                                item: item,
                                status: status(for: item),
                                price: item.price,
                                onTap: { handleTap(for: item) }
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
                viewModel.loadLocalData()
                await viewModel.fetchUserProfile(userRecordID: userRecordID)
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
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
            .alert("Notice", isPresented: .constant(!viewModel.alertMessage.isEmpty)) {
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
                Text("\(viewModel.coins)")
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
        if let purchased = viewModel.purchasedItems.first(where: { $0.itemName == item.rawValue }) {
            return purchased.isSelected ? .selected : .choose
        } else {
            return .price
        }
    }

    private func handleTap(for item: ShopItem) {
        Task {
            if let purchased = viewModel.purchasedItems.first(where: { $0.itemName == item.rawValue }) {
                await viewModel.selectPurchasedItem(purchased)
            } else {
                await viewModel.buyItem(item)
            }
        }
    }
}

