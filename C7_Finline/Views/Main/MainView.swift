//
//  MainView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date()
    @State private var navigateToProfile: Bool = false

    private var filteredTasks: [GoalTask] {
        viewModel.tasks.filter { task in
            Calendar.current.isDate(task.workingTime, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let headerHeight = geo.size.height * 0.5

                ZStack(alignment: .top) {
                    HeaderImageView(height: headerHeight, width: geo.size.width)

                    VStack(spacing: 0) {
                        Spacer(minLength: headerHeight / 2)

                        ContentCardView(
                            viewModel: viewModel,
                            selectedDate: $selectedDate,
                            filteredTasks: filteredTasks
                        )
                        .refreshable {
                            viewModel.fetchUserProfile()
                        }
                    }
                }

                // add task button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                // Add task action
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .padding(.all, 8)
                            }
                            .background(Circle().fill(Color.blue.opacity(0.6)))
                            .buttonStyle(.glass)
                            .padding(.trailing, 28)
                            .padding(.bottom, 16)
                        }
                    }
                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                    selectedDate = Calendar.current.startOfDay(for: Date())
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            navigateToProfile = true
                        } label: {
                            Label(
                                "Profile",
                                systemImage: "person"
                            )
                        }

                        Button {
                            // to shop
                        } label: {
                            Label(
                                "Shop",
                                systemImage: "cart"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToProfile) {
                // ProfileView(viewModel: ProfileViewModel())
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Goal.self, GoalTask.self, UserProfile.self])
}
