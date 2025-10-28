//
//  ContentCardView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct ContentCardView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var selectedDate: Date
    let filteredTasks: [GoalTask]

    private var goalsForSelectedDate: [Goal] {
        viewModel.goals.filter { goal in
            goal.tasks.contains { task in
                Calendar.current.isDate(
                    task.workingTime,
                    inSameDayAs: selectedDate
                )
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemGray6))
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 16) {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DateSelectorView(selectedDate: $selectedDate)

                Divider()

                if filteredTasks.isEmpty {
                    EmptyStateView()
                        .padding(.top, 24)
                } else {
                    TaskListView(
                        viewModel: viewModel,
                        tasks: filteredTasks,
                        goals: goalsForSelectedDate,
                        selectedDate: selectedDate
                    )
                }
            }
            .padding()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentCardView(
        viewModel: MainViewModel(),
        selectedDate: .constant(Date()),
        filteredTasks: []
    )
}
