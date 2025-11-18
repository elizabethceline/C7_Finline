//
//  ProfileView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import CloudKit
import SwiftData
import SwiftUI
import TipKit

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isNameFieldFocused: Bool
    @State private var showAlert = false
    @State private var showShopModal = false

    @State private var navigateToFocus = false
    @State private var userRecordID: CKRecord.ID?

    @StateObject private var shopVM: ShopViewModel

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _shopVM = StateObject(
            wrappedValue: ShopViewModel(
                userProfileManager: viewModel.userProfileManagerInstance,
                networkMonitor: viewModel.networkMonitorInstance
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    ZStack(alignment: .bottomTrailing) {
                        let imageToShow =
                            shopVM.selectedImage
                            ?? viewModel.shopVM?.purchasedItems.first(where: {
                                $0.isSelected
                            })?.shopItem?.image
                            ?? Image("finley")

                        imageToShow
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        Button {
                            showShopModal = true
                            ShopButtonTip.hasClickedShop = true
                        } label: {
                            Image(systemName: "hanger")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.primary))
                        }
                        .popoverTip(ShopButtonTip(), arrowEdge: .bottom)
                        .sheet(isPresented: $showShopModal) {
                            if let id = userRecordID {
                                ShopView(viewModel: shopVM, userRecordID: id)
                                    .presentationDetents([.height(600)])
                            } else {
                                ProgressView("Loading...")
                                    .presentationDetents([.height(300)])
                            }
                        }
                        .offset(x: 40, y: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                    HStack {
                        VStack(alignment: .leading) {
                            if viewModel.isEditingName {
                                TextField(
                                    "Your name",
                                    text: $viewModel.tempUsername
                                )
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .font(.headline)
                                .focused($isNameFieldFocused)
                                .onSubmit {
                                    handleSaveUsername()
                                }
                            } else {
                                Text(
                                    viewModel.username.isEmpty
                                        ? "Your Name" : viewModel.username
                                )
                                .font(.headline)
                            }
                        }
                        .padding(.leading, 8)

                        Spacer()

                        Button {
                            withAnimation {
                                if viewModel.isEditingName {
                                    handleSaveUsername()
                                    isNameFieldFocused = false
                                } else {
                                    viewModel.startEditingUsername()
                                    DispatchQueue.main.asyncAfter(
                                        deadline: .now() + 0.1
                                    ) {
                                        isNameFieldFocused = true
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(Color(uiColor: .label))
                                .font(.title2)
                                .padding(8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .systemBackground))
                    )
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        StatCard(
                            title: "Task Complete",
                            value: "\(viewModel.completedTasks)"
                        )
                        StatCard(
                            title: "Points Earn",
                            value: "\(viewModel.points)"
                        )
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Best Focus Time")
                            .font(.body)
                        Spacer()
                        Text(
                            TimeFormatter.format(
                                seconds: viewModel.bestFocusTime
                            )
                        )
                        .font(.title3)
                        .fontWeight(.semibold)

                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemBackground))
                    )
                    .padding(.horizontal)

                    NavigationLink(
                        destination: EditProductiveHoursView(
                            viewModel: viewModel
                        )
                    ) {
                        HStack {
                            Text("Edit your activity time")
                                .font(.body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .systemBackground))
                        )
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                    shopVM.setModelContext(modelContext)
                    Task {
                        // Ambil record ID hanya sekali
                        if userRecordID == nil {
                            userRecordID = await viewModel.userRecordID
                        }

                        // Setelah ID tersedia, fetch profil dan item shop
                        if let id = userRecordID {
                            await shopVM.fetchUserProfile(userRecordID: id)
                        }
                    }
                }

                .padding(.vertical)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("ProfileDataDidSync")
                )
            ) { _ in
                viewModel.fetchUserProfile()
            }
            .background(Color(uiColor: .systemGray6).ignoresSafeArea())
            .refreshable {
                viewModel.fetchUserProfile()
                if let id = await viewModel.userRecordID {
                    await shopVM.fetchUserProfile(userRecordID: id)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid Username"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func handleSaveUsername() {
        viewModel.saveUsername()
        if viewModel.errorMessage != "" {
            showAlert = true
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
        )
    }
}

struct AsyncShopSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var userRecordID: CKRecord.ID? = nil

    var body: some View {
        Group {
            if let shopVM = viewModel.shopVM,
                let id = userRecordID
            {
                ShopView(viewModel: shopVM, userRecordID: id)
            }
        }
        .task {
            self.userRecordID = await viewModel.userRecordID
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
