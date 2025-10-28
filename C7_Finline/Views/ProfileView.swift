//
//  ProfileView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import Charts
import SwiftData
import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // profile
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                viewModel.username.isEmpty
                                    ? "Your Name" : viewModel.username
                            )
                            .font(.headline)
                            Text("@username")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
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
