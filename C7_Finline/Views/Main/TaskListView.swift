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

    @State private var coverMode: FocusCoverMode?
    @EnvironmentObject var focusVM: FocusSessionViewModel
    @Environment(\.modelContext) private var modelContext

    private var isCoverPresented: Binding<Bool> {
        Binding(
            get: { coverMode != nil },
            set: { if !$0 { coverMode = nil } }
        )
    }

    @State private var removingTaskIds: Set<String> = []
    @State private var showCompleteAlert = false
    @State private var showIncompleteAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedTask: GoalTask?

    @State private var selectedGoal: Goal?
    @State private var goToGoalDetail = false

    private let taskManager: TaskManager
    @StateObject private var taskVM: TaskViewModel

    init(
        viewModel: MainViewModel,
        tasks: [GoalTask],
        goals: [Goal],
        selectedDate: Date,
        networkMonitor: NetworkMonitor
    ) {
        self.viewModel = viewModel
        self.tasks = tasks
        self.goals = goals
        self.selectedDate = selectedDate

        self.taskManager = TaskManager(networkMonitor: networkMonitor)
        _taskVM = StateObject(
            wrappedValue: TaskViewModel(networkMonitor: networkMonitor)
        )
    }

    var body: some View {
        List {
            ForEach(goals) { goal in
                let filteredTasks = tasks.filter { task in
                    goal.tasks.contains(where: { $0.id == task.id })
                }
                let goalTasks = filteredTasks.sorted {
                    $0.workingTime < $1.workingTime
                }

                if !goalTasks.isEmpty {
                    Section {
                        Button {
                            selectedGoal = goal
                            goToGoalDetail = true
                        } label: {
                            GoalHeaderView(goalName: goal.name)
                        }
                        .listRowInsets(
                            .init(top: 0, leading: 4, bottom: 0, trailing: 0)
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                        ForEach(goalTasks) { task in
                            Button {
                                coverMode = .detail(task)
                            } label: {
                                TaskCardView(task: task)
                            }
                            .listRowInsets(
                                .init(
                                    top: -4,
                                    leading: 0,
                                    bottom: 12,
                                    trailing: 0
                                )
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .opacity(removingTaskIds.contains(task.id) ? 0 : 1)
                            .offset(
                                y: removingTaskIds.contains(task.id) ? -10 : 0
                            )
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {
                                if !task.isCompleted {
                                    Button {
                                        selectedTask = task
                                        showCompleteAlert = true
                                    } label: {
                                        Label(
                                            "Complete",
                                            systemImage: "checkmark"
                                        )
                                    }
                                    .tint(.green)
                                } else {
                                    Button {
                                        selectedTask = task
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
                                    selectedTask = task
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                if !task.isCompleted {
                                    Button {
                                        selectedTask = task
                                        showCompleteAlert = true
                                    } label: {
                                        Label(
                                            "Mark as Complete",
                                            systemImage: "checkmark.circle"
                                        )
                                    }
                                } else {
                                    Button {
                                        selectedTask = task
                                        showIncompleteAlert = true
                                    } label: {
                                        Label(
                                            "Mark as Incomplete",
                                            systemImage: "arrow.uturn.left"
                                        )
                                    }
                                }

                                Button {
                                    selectedTask = task
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
                    .listSectionSeparator(.hidden)
                }
            }

            if !tasks.isEmpty {
                Color.clear
                    .frame(height: 48)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationDestination(isPresented: $goToGoalDetail) {
            if let goal = selectedGoal {
                DetailGoalView(
                    goal: goal,
                    goalVM: GoalViewModel(),
                    mainVM: viewModel
                )
            }
        }
        .fullScreenCover(isPresented: isCoverPresented) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusVM.resetSession()
            }
        } content: {
            Group {
                if let mode = coverMode {
                    switch mode {
                    case .detail(let task):
                        DetailTaskView(
                            task: task,
                            taskManager: taskManager,
                            viewModel: taskVM,
                            onStartFocus: {
                                coverMode = .focus
                            },
                            onTaskDeleted: { deletedTask in
                                viewModel.deleteTask(task: deletedTask)
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
                        .environmentObject(focusVM)
                        .environment(\.modelContext, modelContext)
                    }
                }
            }
            .environmentObject(focusVM)
            .environment(\.modelContext, modelContext)
        }
        .environmentObject(focusVM)
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
                Text(
                    "Are you sure you want to mark '\(task.name)' as completed?"
                )
            }
        }
        .alert("Why are you doing this?", isPresented: $showIncompleteAlert) {
            Button("Keep it completed", role: .cancel) { selectedTask = nil }
            Button("Mark as Incomplete") {
                if let task = selectedTask { completeTask(task) }
            }
        } message: {
            if let task = selectedTask {
                Text(
                    "Are you sure you want to mark '\(task.name)' as incomplete?"
                )
            }
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { selectedTask = nil }
            Button("Delete", role: .destructive) {
                if let task = selectedTask { deleteTask(task) }
            }
        } message: {
            if let task = selectedTask {
                Text(
                    "Are you sure you want to delete '\(task.name)'? This action cannot be undone."
                )
            }
        }
    }

    private func completeTask(_ task: GoalTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            removingTaskIds.insert(task.id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.toggleTaskCompletion(task: task)
            removingTaskIds.remove(task.id)
            selectedTask = nil
        }
    }

    private func deleteTask(_ task: GoalTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            removingTaskIds.insert(task.id)
        }
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

    let dummyMonitor = NetworkMonitor()

    let mockVM = MainViewModelMock(goals: [goal], tasks: [task1, task2])

    return TaskListView(
        viewModel: mockVM,
        tasks: [task1, task2],
        goals: [goal],
        selectedDate: Date(),
        networkMonitor: dummyMonitor
    )
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(FocusSessionViewModel())
}

@MainActor
final class MainViewModelMock: MainViewModel {
    init(goals: [Goal], tasks: [GoalTask]) {
        super.init()
        self.goals = goals
        self.tasks = tasks
    }
}
