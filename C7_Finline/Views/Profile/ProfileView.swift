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

    @Query private var profiles: [UserProfile]
    @Query private var allGoals: [Goal]
    @Query private var allTasks: [GoalTask]
    @Query private var purchasedItems: [PurchasedItem]

    @FocusState private var isNameFieldFocused: Bool
    @State private var showAlert = false
    @State private var showShopModal = false
    @State private var userRecordID: CKRecord.ID?

    @StateObject private var shopVM: ShopViewModel

    private var currentProfile: UserProfile? { profiles.first }
    private var completedTasksCount: Int {
        allTasks.filter { $0.isCompleted }.count
    }
    private var selectedShopItem: ShopItem? {
        purchasedItems.first(where: { $0.isSelected })?.shopItem
    }

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
                            selectedShopItem?.image ?? Image("finley")

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
                                ShopView(userRecordID: id)
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
                                    currentProfile?.username.isEmpty ?? true
                                        ? "Your Name"
                                        : currentProfile?.username
                                            ?? "Your Name"
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
                            value: "\(completedTasksCount)"
                        )
                        StatCard(
                            title: "Points Earn",
                            value: "\(currentProfile?.points ?? 0)"
                        )
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Best Focus Time")
                            .font(.body)
                        Spacer()
                        Text(
                            TimeFormatter.format(
                                seconds: currentProfile?.bestFocusTime ?? 0
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

                    if let profile = currentProfile {
                        viewModel.updateFromProfile(profile)
                    }

                    Task {
                        if userRecordID == nil {
                            userRecordID = await viewModel.userRecordID
                        }
                    }
                }
                .onChange(of: currentProfile) { _, newProfile in
                    // Update viewModel when profile changes
                    if let profile = newProfile {
                        viewModel.updateFromProfile(profile)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGray6).ignoresSafeArea())
            .refreshable {
                viewModel.fetchUserProfile()
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

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
