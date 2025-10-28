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
                                TextField("Your name", text: $viewModel.tempUsername)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .font(.headline)
                                    .focused($isNameFieldFocused)
                                    .onSubmit {
                                        viewModel.saveUsername()
                                    }
                            } else {
                                Text(viewModel.username.isEmpty ? "Your Name" : viewModel.username)
                                    .font(.headline)
                            }
                        }
                        .padding(.leading, 8)

                        Spacer()

                        Button {
                            withAnimation {
                                if viewModel.isEditingName {
                                    viewModel.saveUsername()
                                    isNameFieldFocused = false
                                } else {
                                    viewModel.startEditingUsername()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                        Text("12:09:10")
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
                    HStack {
                        Text("Edit your activity time")
                            .font(.body)
                        Spacer()
                        NavigationLink(
                            destination: EditProductiveHoursView(
                                viewModel: viewModel
                            )
                        ) {
                            HStack {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.body)
                            }
                        }
                    }.padding(.vertical, 24)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .systemGray6))
                        )
                        .padding(.horizontal)

                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
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
                .fill(Color(uiColor: .systemGray6))
        )
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
