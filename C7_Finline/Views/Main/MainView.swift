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
                        Spacer(minLength: headerHeight / 1.8)

                        ContentCardView(
                            selectedDate: $selectedDate,
                            filteredTasks: filteredTasks,
                            goals: viewModel.goals
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
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(
                                        Circle().fill(Color.blue.opacity(0.4))
                                    )
                                    .shadow(radius: 2)
                            }
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
                            // to profile
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
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Goal.self, GoalTask.self, UserProfile.self])
}
