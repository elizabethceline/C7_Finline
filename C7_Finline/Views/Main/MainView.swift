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
    @State private var showCreateGoalModal = false

    //NITIP FOCUS MODE START//
    @State private var navigateToFocus: Bool = false
    //NITIP DOCUS MODE END//

    private var unfinishedTasks: [GoalTask] {
        viewModel.tasks.filter { task in
            task.workingTime < Calendar.current.startOfDay(for: Date())
                && !task.isCompleted
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    HeaderView(
                        viewModel: viewModel,
                        unfinishedTasks: unfinishedTasks
                    )

                    ContentCardView(
                        viewModel: viewModel,
                        selectedDate: $selectedDate
                    )

                    Spacer()
                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                    selectedDate = Calendar.current.startOfDay(for: Date())
                }

                Button(action: {
                    showCreateGoalModal.toggle()
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(.all, 8)
                }
                .buttonStyle(.glass)
                .background(Circle().fill(Color.primary))
                .padding(.trailing, 28)
                .padding(.bottom, 16)
                .sheet(isPresented: $showCreateGoalModal) {
                    CreateGoalView(mainVM: viewModel)
                        .presentationDetents([.large])
                }
            }

            .background(Color(uiColor: .systemGray6).ignoresSafeArea())
        }
        //        .toolbar {
        //            ToolbarItem(placement: .topBarTrailing) {
        //                Menu {
        //                    Button {
        //                        navigateToProfile = true
        //                    } label: {
        //                        Label(
        //                            "Profile",
        //                            systemImage: "person"
        //                        )
        //                    }
        //
        //                    Button {
        //                        // to shop
        //                    } label: {
        //                        Label(
        //                            "Shop",
        //                            systemImage: "cart"
        //                        )
        //                    }
        //
        //                    //NITIP FOCUS MODE START
        //                    Button {
        //                        navigateToFocus = true
        //                    } label: {
        //                        Label(
        //                            "Focus Mode",
        //                            systemImage: "lock.desktopcomputer"
        //                        )
        //                    }
        //                    //NITIP FOCUS MODE END//
        //
        //                } label: {
        //                    Image(systemName: "ellipsis")
        //                        .imageScale(.large)
        //                        .foregroundColor(.primary)
        //                }
        //            }
        //        }
        //        .navigationBarTitleDisplayMode(.inline)
        //        .navigationDestination(isPresented: $navigateToProfile) {
        //            ProfileView(viewModel: ProfileViewModel())
        //        }
        //
        //        //NITIP FOCUS MODE START
        //        .navigationDestination(isPresented: $navigateToFocus) {
        //            TestCloud()
        //        }
        //        //NITIP FOCUS MODE END
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Goal.self, GoalTask.self, UserProfile.self])
}
