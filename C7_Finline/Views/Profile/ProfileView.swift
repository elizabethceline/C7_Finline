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
    @Environment(\.colorScheme) var colorScheme

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
                VStack(spacing: 0) {
                    headerSection

                    // Content Section
                    VStack(spacing: 20) {
                        // Name Card
                        nameCard

                        // Stats Grid
                        statsGrid

                        // Best Focus Time Card
                        bestFocusCard

                        // Activity Time Settings
                        activityTimeButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
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
                    if let profile = newProfile {
                        viewModel.updateFromProfile(profile)
                    }
                }
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

    private var headerSection: some View {
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
    }

    private var nameCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.isEditingName {
                    TextField(
                        "Your name",
                        text: $viewModel.tempUsername
                    )
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        handleSaveUsername()
                    }
                } else {
                    Text(
                        currentProfile?.username.isEmpty ?? true
                            ? "Your Name"
                            : currentProfile?.username ?? "Your Name"
                    )
                    .font(.title3)
                    .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 4)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    if viewModel.isEditingName {
                        handleSaveUsername()
                        isNameFieldFocused = false
                    } else {
                        viewModel.startEditingUsername()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isNameFieldFocused = true
                        }
                    }
                }
            } label: {
                Image(
                    systemName: viewModel.isEditingName ? "checkmark" : "pencil"
                )
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .font(.title2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
        )
    }

    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "checkmark.circle.fill",
                title: "Tasks Done",
                value: "\(completedTasksCount)",
                color: .green
            )

            StatCardWithImage(
                image: Image("fishCoins"),
                title: "Points",
                value: "\(currentProfile?.points ?? 0)"
            )
        }
    }

    private var bestFocusCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Best Focus Time")
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    Text(
                        TimeFormatter.format(
                            seconds: currentProfile?.bestFocusTime ?? 0
                        )
                    )
                    .font(.title)
                    .fontWeight(.bold)
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
        )
    }

    private var activityTimeButton: some View {
        NavigationLink(
            destination: EditProductiveHoursView(viewModel: viewModel)
        ) {
            HStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.title)
                    .foregroundColor(Color.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity Time")
                        .font(.body)
                        .fontWeight(.semibold)

                    Text("Customize your schedule")
                        .font(.caption)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .systemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func handleSaveUsername() {
        viewModel.saveUsername()
        if viewModel.errorMessage != "" {
            showAlert = true
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
        )
    }
}

struct StatCardWithImage: View {
    let image: Image
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 12) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
        )
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
