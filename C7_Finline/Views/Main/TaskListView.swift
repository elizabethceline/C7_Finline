//
//  TaskListView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct TaskListView: View {
    let tasks: [GoalTask]
    let goals: [Goal]
    let selectedDate: Date

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(goals) { goal in
                    let goalTasks = tasks.filter { task in
                        goal.tasks.contains(where: { $0.id == task.id })
                    }.sorted { $0.workingTime < $1.workingTime }

                    if !goalTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            GoalHeaderView(goalName: goal.name)

                            ForEach(goalTasks) { task in
                                TaskCardView(task: task)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    TaskListView(
        tasks: [
            GoalTask(
                id: "task_001",
                name: "Study Math",
                workingTime: Date(),
                focusDuration: 25,
                isCompleted: false,
                goal: Goal(
                    id: "goal_001",
                    name: "Learn Algebra",
                    due: Date().addingTimeInterval(7 * 24 * 60 * 60),
                    goalDescription:
                        "Understand the basics of algebraic expressions and equations."
                )
            )
        ],
        goals: [
            Goal(
                id: "goal_001",
                name: "Learn Algebra",
                due: Date().addingTimeInterval(7 * 24 * 60 * 60),
                goalDescription:
                    "Understand the basics of algebraic expressions and equations."
            )
        ],
        selectedDate: Date()
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
