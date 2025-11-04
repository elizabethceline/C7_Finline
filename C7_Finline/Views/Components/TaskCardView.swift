//
//  TaskCardView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct TaskCardView: View {
    let task: GoalTask

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(formattedTime(task.workingTime))
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(task.name)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()

            Text("\(task.focusDuration)m")
                .font(.caption)
                .fontWeight(.bold)
                .padding(6)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(30)
    }
}

#Preview {
    TaskCardView(
        task: GoalTask(
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
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
