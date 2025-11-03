//#
//  GoalDetailView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 01/11/25.
//

import SwiftUI
import SwiftData
import FoundationModels

struct DetailGoalView: View {
    let goal: Goal
    @ObservedObject var goalVM: GoalViewModel
    @StateObject private var taskVM = TaskViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTask: GoalTask?
    @State private var goToTaskDetail = false
    
    @State private var removingTaskIds: Set<String> = []
    @State private var showDeleteAlert = false
    @State private var showCompleteAlert = false
    @State private var taskToDelete: GoalTask?
    @State private var taskToComplete: GoalTask?
    
    var body: some View {
        List {
            Section {
                GoalCardView(goalVM: goalVM, goal: goal)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            
            if taskVM.isLoading {
                Section {
                    ProgressView("Loading tasks...")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else if taskVM.goalTasks.isEmpty {
                Section {
                    Text("No tasks found for this goal.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            } else {
                taskSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Goal Detail")
        .navigationDestination(isPresented: $goToTaskDetail) {
            if let task = selectedTask {
                DetailTaskView(
                    task: task,
                    taskManager: TaskManager(networkMonitor: NetworkMonitor()),
                    viewModel: taskVM
                )
            }
        }
        .task {
            await taskVM.getGoalTaskByGoalId(for: goal, modelContext: modelContext)
        }
        .background(Color.gray.opacity(0.2).ignoresSafeArea())
        
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                taskToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    deleteTaskWithAnimation(task)
                }
            }
        } message: {
            if let task = taskToDelete {
                Text("Are you sure you want to delete '\(task.name)'? This action cannot be undone.")
            }
        }
        
        .alert("Complete Task", isPresented: $showCompleteAlert) {
            Button("Not yet", role: .cancel) {
                taskToComplete = nil
            }
            Button("Yes, Complete") {
                if let task = taskToComplete {
                    completeTaskWithAnimation(task)
                }
            }
        } message: {
            if let task = taskToComplete {
                Text("Are you sure you want to mark '\(task.name)' as completed?")
            }
        }
    }
    
    private var taskSection: some View {
        ForEach(taskVM.groupedPendingGoalTasks, id: \.date) { date, tasks in
            Section(header:
                        Text(date, format: .dateTime.day().month(.wide).year())
                .font(.title3)
                .foregroundColor(.black)
                .fontWeight(.semibold)
            ) {
                ForEach(tasks) { task in
                    Button {
                        selectedTask = task
                        goToTaskDetail = true
                    } label: {
                        TaskCardView(task: task)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    // ANIMATION EFFECTS
                    .opacity(removingTaskIds.contains(task.id) ? 0 : 1)
                    .scaleEffect(removingTaskIds.contains(task.id) ? 0.8 : 1.0)
                    .offset(x: removingTaskIds.contains(task.id) ? -20 : 0)
                    .animation(.easeInOut(duration: 0.3), value: removingTaskIds)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            taskToDelete = task
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                        
                        Button {
                            taskToComplete = task
                            showCompleteAlert = true
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                }
            }
        }
    }
    
    private func deleteTaskWithAnimation(_ task: GoalTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            removingTaskIds.insert(task.id)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                await taskVM.deleteGoalTask(task, modelContext: modelContext)
                removingTaskIds.remove(task.id)
                taskToDelete = nil
            }
        }
    }
    
    private func completeTaskWithAnimation(_ task: GoalTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            removingTaskIds.insert(task.id)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                await taskVM.updateGoalTask(
                    task,
                    name: task.name,
                    workingTime: task.workingTime,
                    focusDuration: task.focusDuration,
                    isCompleted: true,
                    modelContext: modelContext
                )
                removingTaskIds.remove(task.id)
                taskToComplete = nil
            }
        }
    }
}

#Preview {
    let sampleGoal = Goal(
        id: UUID().uuidString,
        name: "Write my Thesis",
        due: Calendar.current.date(
            from: DateComponents(year: 2025, month: 10, day: 14, hour: 9, minute: 41)
        )!,
        goalDescription: "Complete my thesis writing with research and citations."
    )
    
    let goalVM = GoalViewModel()
    
    return NavigationStack {
        DetailGoalView(goal: sampleGoal, goalVM: goalVM)
    }
}
