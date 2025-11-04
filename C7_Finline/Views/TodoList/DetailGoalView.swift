//#
//  GoalDetailView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 01/11/25.
//

import FoundationModels
import SwiftData
import SwiftUI

struct DetailGoalView: View {
    let goal: Goal
    @ObservedObject var goalVM: GoalViewModel
    @StateObject private var taskVM = TaskViewModel()
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTask: GoalTask?
    @State private var goToTaskDetail = false

    @State private var removingTaskIds: Set<String> = []
    @State private var showDeleteAlert = false
    @State private var showBulkDeleteAlert = false
    @State private var showCompleteAlert = false
    @State private var showIncompleteAlert = false
    @State private var taskToDelete: GoalTask?
    @State private var taskToComplete: GoalTask?
    @State private var taskToIncomplete: GoalTask?

    @State private var isSelecting = false
    @State private var selectedTaskIds: Set<String> = []

    var body: some View {
        List {
            Section {
                GoalCardView(goalVM: goalVM, goal: goal)
                    .listRowInsets(
                        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                    )
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
                        .listRowInsets(
                            EdgeInsets(
                                top: 0,
                                leading: 0,
                                bottom: 0,
                                trailing: 0
                            )
                        )
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
            await taskVM.getGoalTaskByGoalId(
                for: goal,
                modelContext: modelContext
            )
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
                Text(
                    "Are you sure you want to delete '\(task.name)'? This action cannot be undone."
                )
            }
        }

        .alert("Delete Selected Tasks", isPresented: $showBulkDeleteAlert) {
            Button("Cancel", role: .cancel) {
                showBulkDeleteAlert = false
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    deleteSelectedTasks()
                }
            }
        } message: {
            Text(
                "Are you sure you want to delete \(selectedTaskIds.count) selected task\(selectedTaskIds.count > 1 ? "s" : "")? This action cannot be undone."
            )
        }

        .alert("Why are you doing this?", isPresented: $showIncompleteAlert) {
            Button("Keep it completed", role: .cancel) {
                taskToIncomplete = nil
            }
            Button("Mark as Incomplete") {
                if let task = taskToIncomplete {
                    incompleteTaskWithAnimation(task)
                }
            }
        } message: {
            if let task = taskToIncomplete {
                Text(
                    "Are you sure you want to mark '\(task.name)' as incomplete?"
                )
            }
        }

        .alert("Did you finish it already?", isPresented: $showCompleteAlert) {
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
                Text(
                    "Are you sure you want to mark '\(task.name)' as completed?"
                )
            }
        }

        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSelecting {
                    Button {
                        withAnimation {
                            isSelecting = false
                            selectedTaskIds.removeAll()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel("Done selecting")
                } else {
                    Menu {
                        Button("Select Tasks") {
                            withAnimation {
                                isSelecting = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }

        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                if isSelecting {

                    Text("\(selectedTaskIds.count) selected")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding(8)
                        .fixedSize()

                    Spacer()

                    Button(role: .destructive) {
                        showBulkDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                    .disabled(selectedTaskIds.isEmpty)

                }
            }
        }
    }

    private var taskSection: some View {
        ForEach(taskVM.groupedPendingGoalTasks, id: \.date) { date, tasks in
            Section(
                header:
                    Text(date, format: .dateTime.day().month(.wide).year())
                    .font(.title3)
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
            ) {
                ForEach(tasks) { task in
                    HStack {
                        if isSelecting {
                            Image(
                                systemName: selectedTaskIds.contains(task.id)
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .font(.title3)
                            .foregroundColor(
                                selectedTaskIds.contains(task.id)
                                    ? .blue : .gray
                            )
                            .padding(.trailing, 4)
                            .onTapGesture {
                                toggleSelection(for: task)
                            }
                        }

                        Button {
                            if isSelecting {
                                toggleSelection(for: task)
                            } else {
                                selectedTask = task
                                goToTaskDetail = true
                            }
                        } label: {
                            TaskCardView(task: task)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowInsets(
                        EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .opacity(removingTaskIds.contains(task.id) ? 0 : 1)
                    .scaleEffect(removingTaskIds.contains(task.id) ? 0.8 : 1.0)
                    .offset(x: removingTaskIds.contains(task.id) ? -20 : 0)
                    .animation(
                        .easeInOut(duration: 0.3),
                        value: removingTaskIds
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                        if !task.isCompleted {
                            Button {
                                taskToComplete = task
                                showCompleteAlert = true
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(.green)
                        } else {
                            Button {
                                taskToIncomplete = task
                                showIncompleteAlert = true
                            } label: {
                                Label(
                                    "Incomplete",
                                    systemImage: "arrow.uturn.left"
                                )
                            }
                            .tint(.gray)
                        }

                        Button {
                            taskToDelete = task
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }

    private func toggleSelection(for task: GoalTask) {
        withAnimation {
            if selectedTaskIds.contains(task.id) {
                selectedTaskIds.remove(task.id)
            } else {
                selectedTaskIds.insert(task.id)
            }
        }
    }

    private func deleteSelectedTasks() {
        Task {
            for id in selectedTaskIds {
                if let task = taskVM.goalTasks.first(where: { $0.id == id }) {
                    await taskVM.deleteGoalTask(
                        task,
                        modelContext: modelContext
                    )
                }
            }
            selectedTaskIds.removeAll()
            isSelecting = false
            await taskVM.getGoalTaskByGoalId(
                for: goal,
                modelContext: modelContext
            )
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

    private func incompleteTaskWithAnimation(_ task: GoalTask) {
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
                    isCompleted: false,
                    modelContext: modelContext
                )
                removingTaskIds.remove(task.id)
                taskToIncomplete = nil
            }
        }
    }
}

#Preview {
    let sampleGoal = Goal(
        id: UUID().uuidString,
        name: "Write my Thesis",
        due: Calendar.current.date(
            from: DateComponents(
                year: 2025,
                month: 10,
                day: 14,
                hour: 9,
                minute: 41
            )
        )!,
        goalDescription:
            "Complete my thesis writing with research and citations."
    )

    let goalVM = GoalViewModel()

    return NavigationStack {
        DetailGoalView(goal: sampleGoal, goalVM: goalVM)
    }
}
