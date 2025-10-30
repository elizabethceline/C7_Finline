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
    
    @State private var removingTaskIds: Set<String> = []

    var body: some View {
        List {
            ForEach(goals) { goal in
                let goalTasks = tasks.filter { task in
                    goal.tasks.contains(where: { $0.id == task.id })
                        && !task.isCompleted
                }
                .sorted { $0.workingTime < $1.workingTime }

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
                                .opacity(removingTaskIds.contains(task.id) ? 0 : 1)
                                .offset(y: removingTaskIds.contains(task.id) ? -10 : 0)
                                .swipeActions(
                                    edge: .trailing,
                                    allowsFullSwipe: false
                                ) {
                                    Button {
                                        _ = withAnimation(.easeInOut(duration: 0.3)) {
                                            removingTaskIds.insert(task.id)
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            viewModel.toggleTaskCompletion(task: task)
                                            removingTaskIds.remove(task.id)
                                        }
                                    } label: {
                                        Label(
                                            "Complete",
                                            systemImage: "checkmark"
                                        )
                                    }
                                    .tint(.green)

                                    Button(role: .destructive) {
                                        _ = withAnimation(.easeInOut(duration: 0.3)) {
                                            removingTaskIds.insert(task.id)
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            viewModel.deleteTask(task: task)
                                            removingTaskIds.remove(task.id)
                                        }
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
        .animation(.easeInOut(duration: 0.3), value: tasks)
        .animation(.easeInOut(duration: 0.3), value: removingTaskIds)
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
