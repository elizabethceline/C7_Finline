import SwiftUI
import CloudKit
import SwiftData

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject var viewModel: ShopViewModel
    let userRecordID: CKRecord.ID

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header koin
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("\(viewModel.coins)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        ZStack {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 28, height: 28)
                            Text("$")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.primary)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 30)

                // Daftar item toko
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 50) {
                    ForEach(ShopItem.allCases, id: \.rawValue) { item in
                        ShopCardView(
                            item: item,
                            isSelected: viewModel.selectedItem == item,
                            onTap: {
                                viewModel.selectedItem = item
                                Task {
                                    await viewModel.reduceCoins(by: item.price)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .task {
                viewModel.setModelContext(modelContext)
                await viewModel.fetchUserProfile(userRecordID: userRecordID)
            }
            .background(Color(.systemBackground))
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
            .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                Button("OK") { viewModel.errorMessage = "" }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
