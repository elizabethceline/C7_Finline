//
//  ContentCardView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct ContentCardView: View {
    @ObservedObject var viewModel: MainViewModel
    let goals: [Goal]
    let tasks: [GoalTask]
    @Binding var selectedDate: Date
    let networkMonitor: NetworkMonitor

    @GestureState private var dragOffset: CGFloat = 0
    @State private var contentOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    @State private var isHorizontalDrag = false

    private let calendar = Calendar.current

    var filteredTasks: [GoalTask] {
        let dateTasks = tasks.filter { task in
            Calendar.current.isDate(task.workingTime, inSameDayAs: selectedDate)
        }

        switch viewModel.taskFilter {
        case .all:
            return dateTasks
        case .unfinished:
            return dateTasks.filter { !$0.isCompleted }
        case .finished:
            return dateTasks.filter { $0.isCompleted }
        }
    }

    var filteredGoals: [Goal] {
        goals.filter { goal in
            goal.tasks.contains { task in
                Calendar.current.isDate(
                    task.workingTime,
                    inSameDayAs: selectedDate
                )
            }
        }
    }

    private func changeDay(delta: Int, width: CGFloat) {
        if let newDate = calendar.date(
            byAdding: .day,
            value: delta,
            to: selectedDate
        ) {
            isAnimating = true

            // Animate content sliding out
            withAnimation(.easeInOut(duration: 0.3)) {
                contentOffset =
                    delta > 0
                    ? -width : width
            }

            // Change date and reset position after slide out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                selectedDate = calendar.startOfDay(for: newDate)
                contentOffset =
                    delta > 0
                    ? width : -width

                // Slide in from opposite side
                withAnimation(.easeOut(duration: 0.25)) {
                    contentOffset = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isAnimating = false
                }
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let drag = DragGesture(minimumDistance: 10)
                .onChanged { value in
                    if !isAnimating && !isHorizontalDrag {
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(value.translation.height)
                        if horizontal > vertical {
                            isHorizontalDrag = true
                        }
                    }
                }
                .updating($dragOffset) { value, state, _ in
                    if !isAnimating && isHorizontalDrag {
                        state = value.translation.width
                    }
                }
                .onEnded { value in
                    defer { isHorizontalDrag = false }

                    if !isAnimating && isHorizontalDrag {
                        if value.translation.width < -50 {
                            changeDay(delta: 1, width: geo.size.width)
                        } else if value.translation.width > 50 {
                            changeDay(delta: -1, width: geo.size.width)
                        }
                    }
                }

            VStack(spacing: 0) {
                if filteredTasks.isEmpty {
                    ScrollView(showsIndicators: false) {
                        EmptyStateView()
                            .padding(.top, 24)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                } else {
                    TaskListView(
                        viewModel: viewModel,
                        tasks: filteredTasks,
                        goals: filteredGoals,
                        selectedDate: selectedDate,
                        networkMonitor: networkMonitor
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
            .offset(x: contentOffset + dragOffset)
            .opacity(
                isAnimating
                    ? (contentOffset == 0 ? 1 : 0.5)
                    : 1 - abs(dragOffset) / geo.size.width * 0.5
            )
            .contentShape(Rectangle())
            .gesture(drag)
            .scrollDisabled(isHorizontalDrag)
        }
        .refreshable {
            await viewModel.fetchGoals()
        }
    }

}

#Preview {
    ContentCardView(
        viewModel: MainViewModel(),
        goals: [],
        tasks: [],
        selectedDate: .constant(Date()),
        networkMonitor: NetworkMonitor()
    )
}
