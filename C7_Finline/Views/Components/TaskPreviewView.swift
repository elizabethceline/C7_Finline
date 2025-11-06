//
//  TaskPreviewView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 06/11/25.
//

import SwiftUI

struct TaskPreviewView: View {
    let task: GoalTask

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text(task.name.capitalized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(.label))

            // Details
            VStack(spacing: 0) {
                // Goal
                if let goalName = task.goal?.name {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .foregroundColor(.primary)
                            Text("Goal")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        Spacer()
                        Text(goalName)
                            .font(.body)
                            .foregroundColor(Color(.label))
                    }
                    .padding()

                    Divider()
                        .padding(.leading)
                }

                // Date
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.primary)
                        Text("Date")
                            .font(.subheadline)

                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    Text(formattedDate(task.workingTime))
                        .font(.body)
                        .foregroundColor(Color(.label))
                }
                .padding()

                Divider()
                    .padding(.leading)

                // Time
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundColor(.primary)
                        Text("Time")
                            .font(.subheadline)

                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    Text(formattedTime(task.workingTime))
                        .font(.body)
                        .foregroundColor(Color(.label))
                }
                .padding()

                Divider()
                    .padding(.leading)

                // Focus Duration
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .foregroundColor(.primary)
                        Text("Focus Duration")
                            .font(.subheadline)

                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    Text("\(task.focusDuration) mins")
                        .font(.body)
                        .foregroundColor(Color(.label))
                }
                .padding()

                // Status (if completed)
                //                if task.isCompleted {
                //                    Divider()
                //                        .padding(.leading)
                //
                //                    HStack {
                //                        HStack(spacing: 8) {
                //                            Image(systemName: "checkmark.circle.fill")
                //                                .foregroundColor(.green)
                //                            Text("Status")
                //                                .font(.subheadline)
                //                        }
                //                        Spacer()
                //                        Text("Completed")
                //                            .font(.headline)
                //                            .foregroundColor(.green)
                //                    }
                //                    .padding()
                //                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                //                }
            }
            .background(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .systemGray6))
    }
}

#Preview {
    TaskPreviewView(
        task: GoalTask(
            id: "goaltask-001",
            name: "Design Landing Page",
            workingTime: Date(),
            focusDuration: 45,
            isCompleted: true,
            goal: Goal(
                id: "goal-001",
                name: "Website Redesign",
                due: Date().addingTimeInterval(86400 * 7),
                goalDescription:
                    "Redesign the company website to improve user experience."
            )
        )
    )
}
