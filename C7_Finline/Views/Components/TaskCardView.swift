//
//  TaskCardView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct TaskCardView: View {
    @Environment(\.colorScheme) var colorScheme

    let task: GoalTask

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    formattedTimeRange(
                        start: task.workingTime,
                        durationMinutes: task.focusDuration
                    )
                )
                .font(.caption)
                .foregroundColor(Color(uiColor: .secondaryLabel))

                Text(task.name.capitalized)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color(uiColor: .label))
                    .strikethrough(task.isCompleted, color: Color(.label))
                    .opacity(task.isCompleted ? 0.6 : 1.0)
            }

            Spacer()

            Text("\(task.focusDuration)m")
                .font(.callout)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundColor(
                    Color.primary
                )
                .cornerRadius(12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    (colorScheme == .light
                        ? Color(.systemBackground) : Color(.systemGray6))
                )
        )
        .opacity(task.isCompleted ? 0.6 : 1)
    }

    private func formattedTimeRange(start: Date, durationMinutes: Int) -> String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let endTime =
            Calendar.current.date(
                byAdding: .minute,
                value: durationMinutes,
                to: start
            ) ?? start
        return
            "\(formatter.string(from: start)) - \(formatter.string(from: endTime))"
    }
}

#Preview {
    TaskCardView(
        task: GoalTask(
            id: "task_001",
            name: "Study Math",
            workingTime: Calendar.current.date(
                bySettingHour: 18,
                minute: 0,
                second: 0,
                of: Date()
            )!,
            focusDuration: 20,
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
    .background(Color.black)
}
