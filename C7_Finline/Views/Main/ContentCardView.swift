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
}

#Preview {
    ContentCardView(
        viewModel: MainViewModel(),
        selectedDate: .constant(Date()),
    )
}
