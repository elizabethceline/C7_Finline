//
//  DebugData.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 28/10/25.
//

import SwiftUI
import SwiftData

struct DebugDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GoalTask.workingTime, order: .forward) private var tasks: [GoalTask]
    @Query(sort: \Goal.due, order: .forward) private var goals: [Goal]

    var body: some View {
        NavigationStack {
            List {
                Section("Stored Goals (\(goals.count))") {
                    ForEach(goals) { goal in
                        VStack(alignment: .leading) {
                            Text(goal.name)
                                .font(.headline)
                            Text("Due: \(goal.due.formatted(date: .long, time: .shortened))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let desc = goal.goalDescription {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section("Stored Tasks (\(tasks.count))") {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.name)
                                .font(.headline)
                            Text("\(task.workingTime.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Focus: \(task.focusDuration) mins | Goal: \(task.goal?.name ?? "-")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("SwiftData Debug")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All", role: .destructive) {
                        clearAllData()
                    }
                }
            }
        }
    }

    private func clearAllData() {
        for goal in goals { modelContext.delete(goal) }
        for task in tasks { modelContext.delete(task) }
        try? modelContext.save()
    }
}

#Preview {
    DebugDataView()
        .modelContainer(for: [Goal.self, GoalTask.self])
}
