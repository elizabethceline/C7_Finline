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
        GeometryReader { geo in
            let headerHeight = geo.size.height * 0.5

            ZStack(alignment: .top) {
                HeaderImageView(height: headerHeight, width: geo.size.width)

                VStack(spacing: 0) {
                    Spacer(minLength: headerHeight / 1.5)

                    ContentCardView(
                        selectedDate: $selectedDate,
                        filteredTasks: filteredTasks,
                        goals: viewModel.goals
                    )
                }

                // add task button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // add task action
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
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                selectedDate = Calendar.current.startOfDay(for: Date())
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Goal.self, GoalTask.self, UserProfile.self])
}
