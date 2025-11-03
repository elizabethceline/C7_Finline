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

    @GestureState private var dragOffset: CGFloat = 0
    private let calendar = Calendar.current

    var tasks: [GoalTask] {
        viewModel.filterTasksByDate(for: selectedDate)
    }

    var goals: [Goal] {
        viewModel.filterGoalsByDate(for: selectedDate)
    }

    private func changeDay(delta: Int) {
        if let newDate = calendar.date(
            byAdding: .day,
            value: delta,
            to: selectedDate
        ) {
            withAnimation(.easeInOut) {
                selectedDate = calendar.startOfDay(for: newDate)
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let drag = DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    if value.translation.width < -50 {
                        changeDay(delta: 1)
                    } else if value.translation.width > 50 {
                        changeDay(delta: -1)
                    }
                }

            VStack(spacing: 0) {
                if tasks.isEmpty {
                    ScrollView(showsIndicators: false) {
                        EmptyStateView()
                            .padding(.top, 24)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                } else {
                    TaskListView(
                        viewModel: viewModel,
                        tasks: tasks,
                        goals: goals,
                        selectedDate: selectedDate
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(x: dragOffset)
            .animation(.spring(), value: selectedDate)
            .contentShape(Rectangle())
            .gesture(drag)
        }
        .refreshable {
            await viewModel.fetchGoals()
        }
    }

}

#Preview {
    ContentCardView(
        viewModel: MainViewModel(),
        selectedDate: .constant(Date()),
    )
}
