//
//  ProfileView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isNameFieldFocused: Bool
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            )

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
                                .foregroundColor(.black)
                                .font(.title2)
                                .padding(8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .systemGray6))
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

                    // Best Focus Time
                    HStack {
                        Text("Best Focus Time")
                            .font(.body)
                        Spacer()
                        Text(formatTime(viewModel.bestFocusTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemGray6))
                    )
                    .padding(.horizontal)

                    // Edit productive hours
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
                                .fill(Color(uiColor: .systemGray6))
                        )
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                }
                .padding(.vertical)
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

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
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
                .fill(Color(uiColor: .systemGray6))
        )
    }
}


#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
