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

    private var filteredTasks: [GoalTask] {
        viewModel.tasks.filter { task in
            Calendar.current.isDate(task.workingTime, inSameDayAs: selectedDate)
                && !task.isCompleted
        }
    }

    private var goalsForSelectedDate: [Goal] {
        viewModel.goals.filter { goal in
            goal.tasks.contains { task in
                Calendar.current.isDate(
                    task.workingTime,
                    inSameDayAs: selectedDate
                )
                    && !task.isCompleted
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                Text(selectedDate.formatted(.dateTime.month(.wide)) + " ")
                    .foregroundColor(.primary)

                Text(selectedDate.formatted(.dateTime.year()))
            }
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
        .padding(.horizontal)
    }
}

#Preview {
    ContentCardView(
        viewModel: MainViewModel(),
        selectedDate: .constant(Date()),
    )
}
