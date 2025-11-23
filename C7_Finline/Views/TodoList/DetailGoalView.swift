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
    @ObservedObject var mainVM: MainViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var coverMode: FocusCoverMode?
    @EnvironmentObject var focusVM: FocusSessionViewModel
    private var isCoverPresented: Binding<Bool> {
        Binding(
            get: { coverMode != nil },
            set: { if !$0 { coverMode = nil } }
        )
    }

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

    @State private var showAddTaskModal = false

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
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray6).ignoresSafeArea())
        .listStyle(.insetGrouped)
        .navigationTitle("Goal Detail")
        .sheet(isPresented: $showAddTaskModal) {
            CreateTaskManuallyView(
                taskVM: taskVM,
                taskDeadline: goal.due,
                goalId: goal.id,
                onTaskCreated: {
                    Task {
                        print(
                            "Before refresh - Goal has \(goal.tasks.count) tasks"
                        )
                        await taskVM.getGoalTaskByGoalId(
                            for: goal,
                            modelContext: modelContext
                        )
                        print(
                            "After refresh - TaskVM has \(taskVM.goalTasks.count) tasks"
                        )
                    }
                }
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: isCoverPresented) {
            Group {
                if let mode = coverMode {
                    switch mode {
                    case .detail(let task):
                        DetailTaskView(
                            task: task,
                            taskManager: TaskManager(
                                networkMonitor: NetworkMonitor.shared
                            ),
                            viewModel: taskVM,
                            onStartFocus: {
                                coverMode = .focus
                            },
                            onTaskDeleted: { deletedTask in
                                Task {
                                    taskVM.goalTasks.removeAll {
                                        $0.id == deletedTask.id
                                    }
                                    mainVM.deleteTask(task: deletedTask)
                                    try? modelContext.save()
                                }
                            }

                        )
                    case .focus:
                        FocusModeView(
                            onGiveUp: { task in
                                coverMode = .detail(task)
                            },
                            onSessionEnd: {
                                coverMode = nil
                            }
                        )
                    }
                }
            }
            .environmentObject(focusVM)
            .environment(\.modelContext, modelContext)
        }
        .task {
            await taskVM.getGoalTaskByGoalId(
                for: goal,
                modelContext: modelContext
            )
        }

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
                        Button("Delete Task") {
                            withAnimation {
                                isSelecting = true
                            }
                        }
                        Button("Add Task") {
                            showAddTaskModal = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }

        //        .toolbar {
        //            ToolbarItemGroup(placement: .bottomBar) {
        //                if isSelecting {
        //
        //                    Text("\(selectedTaskIds.count) selected")
        //                        .foregroundColor(.gray)
        //                        .font(.subheadline)
        //                        .padding(8)
        //                        .fixedSize()
        //
        //                    Spacer()
        //
        //                    Button(role: .destructive) {
        //                        showBulkDeleteAlert = true
        //                    } label: {
        //                        Label("Delete", systemImage: "trash")
        //                    }
        //                    .tint(.red)
        //                    .disabled(selectedTaskIds.isEmpty)
        //
        //                }
        //            }
        //        }
    }

    private var taskSection: some View {
        ForEach(taskVM.groupedPendingGoalTasks, id: \.date) { date, tasks in
            Section(
                header:
                    Text(date, format: .dateTime.day().month(.wide).year())
                    .font(.title3)
                    .fontWeight(.semibold)
            ) {
                ForEach(tasks) { task in
                    HStack {
                        if isSelecting {
                            Button {
                                showDeleteAlert = true
                                taskToDelete = task
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .padding(.trailing, 4)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            if isSelecting {
                                toggleSelection(for: task)
                            } else {
                                //                                selectedTask = task
                                //                                goToTaskDetail = true
                                coverMode = .detail(task)
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

                    .contextMenu {
                        if !task.isCompleted {
                            Button {
                                taskToComplete = task
                                showCompleteAlert = true
                            } label: {
                                Label(
                                    "Mark as Complete",
                                    systemImage: "checkmark.circle"
                                )
                            }
                        } else {
                            Button {
                                taskToIncomplete = task
                                showIncompleteAlert = true
                            } label: {
                                Label(
                                    "Mark as Incomplete",
                                    systemImage: "arrow.uturn.left"
                                )
                            }
                        }

                        Button {
                            taskToDelete = task
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Task", systemImage: "trash")
                        }

                        Divider()

                        Button {
                            coverMode = .detail(task)
                        } label: {
                            Label(
                                "View Detail",
                                systemImage: "info.circle"
                            )
                        }
                    } preview: {
                        TaskPreviewView(task: task)
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

        HapticManager.shared.playDestructiveHaptic()

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

        HapticManager.shared.playDestructiveHaptic()

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

        HapticManager.shared.playSuccessHaptic()

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

        HapticManager.shared.playUnsavedChangesHaptic()

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
        DetailGoalView(
            goal: sampleGoal,
            goalVM: goalVM,
            mainVM: MainViewModel()
        )
    }
    .environmentObject(FocusSessionViewModel())  // <-- ADD THIS
}
