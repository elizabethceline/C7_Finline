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
    }
    
    private var taskSection: some View {
        ForEach(taskVM.groupedGoalTasks, id: \.date) { date, tasks in
            Section(header:
                        Text(date, format: .dateTime.day().month(.wide).year())
                .font(.title3)
                .foregroundColor(.primary)
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task{
                                await taskVM.deleteGoalTask(task, modelContext: modelContext)
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        Button(role: .confirm) {
                            Task{
                                await taskVM.updateGoalTask(task, name: task.name, workingTime: task.workingTime, focusDuration: task.focusDuration, isCompleted: true, modelContext: modelContext)
                            }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .tint(.blue)
                    }
                }
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
