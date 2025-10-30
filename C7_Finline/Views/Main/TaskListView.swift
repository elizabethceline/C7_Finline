//
//  TaskListView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: MainViewModel
    let tasks: [GoalTask]
    let goals: [Goal]
    let selectedDate: Date

    var body: some View {
        List {
            ForEach(goals) { goal in
                let goalTasks = tasks.filter { task in
                    goal.tasks.contains(where: { $0.id == task.id })
                }.sorted { $0.workingTime < $1.workingTime }

                if !goalTasks.isEmpty {
                    Section {
                        GoalHeaderView(goalName: goal.name)
                            .listRowInsets(
                                EdgeInsets(
                                    top: 8,
                                    leading: 0,
                                    bottom: 8,
                                    trailing: 0
                                )
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        ForEach(goalTasks) { task in
                            TaskCardView(task: task)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 8,
                                        leading: 0,
                                        bottom: 8,
                                        trailing: 0
                                    )
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(
                                    edge: .trailing,
                                    allowsFullSwipe: false
                                ) {
                                    Button {
                                        viewModel.toggleTaskCompletion(
                                            task: task
                                        )
                                    } label: {
                                        Label(
                                            "Complete",
                                            systemImage: "checkmark"
                                        )
                                    }
                                    .tint(.green)

                                    Button(role: .destructive) {
                                        viewModel.deleteTask(task: task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }

                        }
                    }
                    .listSectionSeparator(.hidden)
                }
            }
        }
        .animation(.default, value: viewModel.tasks)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    let goal = Goal(
        id: "goal_001",
        name: "Learn Algebra",
        due: Date().addingTimeInterval(7 * 24 * 60 * 60),
        goalDescription:
            "Understand the basics of algebraic expressions and equations."
    )

    let task1 = GoalTask(
        id: "task_001",
        name: "Study Math",
        workingTime: Date(),
        focusDuration: 25,
        isCompleted: false,
        goal: goal
    )

    let task2 = GoalTask(
        id: "task_002",
        name: "Practice Exercises",
        workingTime: Date().addingTimeInterval(2 * 60 * 60),
        focusDuration: 30,
        isCompleted: true,
        goal: goal
    )

    goal.tasks = [task1, task2]

    return TaskListView(
        viewModel: MainViewModel(),
        tasks: [
            task1, task2, task1, task2, task2, task1, task2, task1, task2,
            task1, task2, task2, task1, task2,
        ],
        goals: [goal],
        selectedDate: Date()
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
