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

    var tasks: [GoalTask] {
        viewModel.filterTasksByDate(for: selectedDate)
    }

    var goals: [Goal] {
        viewModel.filterGoalsByDate(for: selectedDate)
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

            DateWeekPagerView(selectedDate: $selectedDate)

            Divider()

            if tasks.isEmpty {
                ScrollView(showsIndicators: false) {

                    EmptyStateView()
                        .padding(.top, 24)
                }
                .refreshable {
                    await viewModel.fetchGoals()
                }
            } else {
                TaskListView(
                    viewModel: viewModel,
                    tasks: tasks,
                    goals: goals,
                    selectedDate: selectedDate
                )
                .refreshable {
                    await viewModel.fetchGoals()
                }
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
