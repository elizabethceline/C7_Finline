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
    @State private var showCompleteAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedTask: GoalTask?
    @State private var navigateToDetail = false
    
    @State private var selectedGoal: Goal?
    @State private var goToGoalDetail = false
    
    private let taskManager = TaskManager(networkMonitor: NetworkMonitor())
    @StateObject private var taskVM = TaskViewModel(networkMonitor: NetworkMonitor())
    
    var body: some View {
        List {
            ForEach(goals) { goal in
                let goalTasks = tasks.filter { task in
                    goal.tasks.contains(where: { $0.id == task.id })
                }
                .sorted { $0.workingTime < $1.workingTime }
                
                if !goalTasks.isEmpty {
                    Section {
                        Button {
                            selectedGoal = goal
                            goToGoalDetail = true
                        } label: {
                            GoalHeaderView(goalName: goal.name)
                        }
                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        
                        
                        ForEach(goalTasks) { task in
                            Button {
                                selectedTask = task
                                navigateToDetail = true
                            } label: {
                                TaskCardView(task: task)
                            }
                            .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .opacity(removingTaskIds.contains(task.id) ? 0 : 1)
                            .offset(y: removingTaskIds.contains(task.id) ? -10 : 0)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                
                                Button {
                                    selectedTask = task
                                    showCompleteAlert = true
                                } label: {
                                    Label("Complete", systemImage: "checkmark")
                                }
                                .tint(.green)
                                
                                Button {
                                    selectedTask = task
                                    showDeleteAlert = true
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
        .navigationDestination(isPresented: $navigateToDetail) {
            if let task = selectedTask {
                DetailTaskView(
                    task: task,
                    taskManager: taskManager,
                    viewModel: taskVM
                )
            }
        }
        .navigationDestination(isPresented: $goToGoalDetail) {
            if let goal = selectedGoal {
                DetailGoalView(
                    goal: goal,
                    goalVM: GoalViewModel()
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: tasks)
        .animation(.easeInOut(duration: 0.3), value: removingTaskIds)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .bottom)
        .alert("Did you finish it already?", isPresented: $showCompleteAlert) {
            Button("Not yet", role: .cancel) { selectedTask = nil }
            Button("Yes") {
                if let task = selectedTask { completeTask(task) }
            }
        } message: {
            if let task = selectedTask {
                Text("Are you sure you want to mark '\(task.name)' as completed?")
            }
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { selectedTask = nil }
            Button("Delete", role: .destructive) {
                if let task = selectedTask { deleteTask(task) }
            }
        } message: {
            if let task = selectedTask {
                Text("Are you sure you want to delete '\(task.name)'? This action cannot be undone.")
            }
        }
    }
    
    private func completeTask(_ task: GoalTask) {
        withAnimation(.easeInOut(duration: 0.3)) { removingTaskIds.insert(task.id) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.toggleTaskCompletion(task: task)
            removingTaskIds.remove(task.id)
            selectedTask = nil
        }
    }
    
    private func deleteTask(_ task: GoalTask) {
        withAnimation(.easeInOut(duration: 0.3)) { removingTaskIds.insert(task.id) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.deleteTask(task: task)
            removingTaskIds.remove(task.id)
            selectedTask = nil
        }
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
