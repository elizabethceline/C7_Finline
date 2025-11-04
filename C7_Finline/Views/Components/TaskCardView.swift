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
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedTime(task.workingTime))
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                Text(task.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color(uiColor: .label))
                    .strikethrough(task.isCompleted, color: Color(.label))
                    .opacity(task.isCompleted ? 0.6 : 1.0)
            }

            Spacer()

            Text("\(task.focusDuration)m")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    task.isCompleted
                        ? Color.gray.opacity(0.2) : Color.secondary
                )
                .foregroundColor(
                    task.isCompleted ? Color(uiColor: .label) : .black
                )
                .cornerRadius(12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(uiColor: .systemBackground))
        )
        .opacity(task.isCompleted ? 0.6 : 1)
    }
}

#Preview {
    TaskCardView(
        task: GoalTask(
            id: "task_001",
            name: "Study Math",
            workingTime: Date(),
            focusDuration: 25,
            isCompleted: true,
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
