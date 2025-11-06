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
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var goalVM = GoalViewModel()
    
    @State private var coverMode: FocusCoverMode?
        @EnvironmentObject var focusVM: FocusSessionViewModel
    
    private var isCoverPresented: Binding<Bool> {
            Binding(
                get: { coverMode != nil },
                set: { if !$0 { coverMode = nil } }
            )
        }
    
    @State private var goals: [Goal] = []
    @State private var tasks: [GoalTask] = []
    @State private var isLoading = false
    @State private var syncMessage: String = ""
    
    private let goalManager: GoalManager
    private let taskManager: TaskManager
    
    @State private var selectedTask: GoalTask? = nil
    //@State private var showDetailModal = false
    
    @State private var selectedGoal: Goal? = nil
    @State private var showGoalDetailModal = false
    
    init() {
        let networkMonitor = NetworkMonitor()
        self.goalManager = GoalManager(networkMonitor: networkMonitor)
        self.taskManager = TaskManager(networkMonitor: networkMonitor)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView("Syncing with iCloud…")
                } else {
                    if !syncMessage.isEmpty {
                        Section {
                            Text(syncMessage)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Section("Stored Goals (\(goals.count))") {
                        ForEach(goals) { goal in
                            NavigationLink {
                                DetailGoalView(goal: goal, goalVM: goalVM)
                            } label: {
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
                                    if goal.needsSync {
                                        Text("⚠️ Pending Sync")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("Stored Tasks (\(tasks.count))") {
                        ForEach(tasks) { task in
                            Button {
//                                selectedTask = task
//                                showDetailModal = true
                                coverMode = .detail(task)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.name)
                                        .font(.headline)
                                    Text("\(task.workingTime.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Focus: \(task.focusDuration) mins | Goal: \(task.goal?.name ?? "-")")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    if task.needsSync {
                                        Text("⚠️ Pending Sync")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
//                    .sheet(isPresented: $showDetailModal) {
//                        if let selectedTask {
//                            DetailTaskView(task: selectedTask, taskManager: TaskManager(networkMonitor: NetworkMonitor()), viewModel: taskViewModel)
//                        }
//                    }
                    .fullScreenCover(isPresented: isCoverPresented) {
                                        Group {
                                            if let mode = coverMode {
                                                switch mode {
                                                case .detail(let task):
                                                    DetailTaskView(
                                                        task: task,
                                                        taskManager: taskManager,
                                                        viewModel: taskViewModel,
                                                        onStartFocus: {
                                                            coverMode = .focus
                                                        }
                                                    )
                                                case .focus:
                                                    FocusModeView(onGiveUp: { task in 
                                                        coverMode = .detail(task)
                                                                    })
                                                }
                                            }
                                        }
                                        .environmentObject(focusVM)
                                        .environment(\.modelContext, modelContext)
                                    }
                }
            }
            .navigationTitle("SwiftData Debug")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reload") {
                        Task { await loadData() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All", role: .destructive) {
                        clearAllData()
                    }
                }
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        await MainActor.run {
            isLoading = true
            syncMessage = "Fetching & syncing with iCloud..."
        }
        
        do {
            let fetchedGoals = try await goalManager.fetchGoals(modelContext: modelContext)
            let fetchedTasks = try await taskManager.fetchTasks(for: fetchedGoals, modelContext: modelContext)
            
            await MainActor.run {
                self.goals = fetchedGoals
                self.tasks = fetchedTasks
                self.syncMessage = "Fetched from iCloud successfully ✅"
            }
            
            await goalManager.syncPendingGoals(modelContext: modelContext)
            await taskManager.syncPendingTasks(modelContext: modelContext)
            await goalManager.syncPendingDeletions()
            await taskManager.syncPendingDeletions()
            
            await MainActor.run {
                self.syncMessage = "Sync completed ✅"
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                syncMessage = "❌ Sync failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func clearAllData() {
        for goal in goals { modelContext.delete(goal) }
        for task in tasks { modelContext.delete(task) }
        try? modelContext.save()
        goals.removeAll()
        tasks.removeAll()
        syncMessage = "All local data cleared."
    }
}

#Preview {
    DebugDataView()
        .modelContainer(for: [Goal.self, GoalTask.self])
}
