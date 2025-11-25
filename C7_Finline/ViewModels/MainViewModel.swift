//
//  MainViewModel.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import CloudKit
import Combine
import Foundation
import SwiftData
import WidgetKit

class MainViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var tasks: [GoalTask] = []
    @Published var isLoading = false
    @Published var error: String = ""
    @Published var selectedDate: Date = Date()
    @Published var taskFilter: TaskFilter = .unfinished

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    private let networkMonitor: NetworkMonitor
    private let goalManager: GoalManager
    private let taskManager: TaskManager
    private let syncManager: BackgroundSyncManager

    @MainActor
    var isSignedInToiCloud: Bool {
        CloudKitManager.shared.isSignedInToiCloud
    }

    @MainActor
    var userRecordID: CKRecord.ID? {
        get async {
            do {
                return try await CloudKitManager.shared.fetchUserRecordID()
            } catch {
                print("Failed to get user record ID: \(error)")
                return nil
            }
        }
    }

    init(
        networkMonitor: NetworkMonitor = .shared,
        syncManager: BackgroundSyncManager = .shared
    ) {
        self.networkMonitor = networkMonitor
        self.syncManager = syncManager
        self.goalManager = GoalManager(networkMonitor: networkMonitor)
        self.taskManager = TaskManager(networkMonitor: networkMonitor)

        observeNetworkStatus()
        observeSyncCompletion()
    }

    @MainActor
    func setModelContext(_ context: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = context

        Task {
            if networkMonitor.isConnected, isSignedInToiCloud {
                isLoading = true

                await syncManager.performSync(
                    modelContext: context,
                    reason: "Initial app launch"
                )

                isLoading = false
            }
        }
    }

    // check if online
    private func observeNetworkStatus() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected,
                    self.isSignedInToiCloud,
                    self.modelContext != nil
                {
                    Task {
                        await self.syncManager.performSync(
                            modelContext: self.modelContext,
                            reason: "Network reconnected"
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func observeSyncCompletion() {
        NotificationCenter.default.publisher(for: .syncDidComplete)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                print("Sync completed")
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .syncDidFail)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let error = notification.userInfo?["error"] as? Error {
                    self?.error = error.localizedDescription
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func updatePublishedGoals(_ goals: [Goal]) {
        self.goals = goals
    }

    @MainActor
    private func updatePublishedTasks(_ tasks: [GoalTask]) {
        self.tasks = tasks
        print("Updated tasks: \(tasks.count)")
    }

    @MainActor
    func refreshData() async {
        guard let modelContext = modelContext else { return }

        isLoading = true
        await syncManager.triggerManualSync(modelContext: modelContext)
        isLoading = false
    }

    @MainActor
    func fetchGoals() async {
        guard let modelContext = modelContext,
            isSignedInToiCloud,
            networkMonitor.isConnected
        else {
            return
        }

        isLoading = true

        do {
            let fetchedGoals = try await goalManager.fetchGoals(
                modelContext: modelContext
            )
            updatePublishedGoals(fetchedGoals)
            try? modelContext.save()
            await fetchAllTasks()
        } catch {
            self.error = "Failed to fetch goals: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // crud tasks
    @MainActor
    func fetchAllTasks() async {
        guard let modelContext = modelContext,
            isSignedInToiCloud,
            networkMonitor.isConnected
        else {
            return
        }

        do {
            let fetchedTasks = try await taskManager.fetchTasks(
                for: goals,
                modelContext: modelContext
            )
            updatePublishedTasks(fetchedTasks)
            try? modelContext.save()
        } catch {
            self.error = "Failed to fetch tasks: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteTask(task: GoalTask) {
        guard let modelContext = modelContext else { return }

        self.tasks.removeAll { $0.id == task.id }
        taskManager.deleteTask(task: task, modelContext: modelContext)

        do {
            try modelContext.save()

            WidgetCenter.shared.reloadTimelines(ofKind: "FinlineWidget")
        } catch {
            print("Error deleting task: \(error.localizedDescription)")
        }
    }

    @MainActor
    func toggleTaskCompletion(task: GoalTask) {
        taskManager.toggleTaskCompletion(task: task)

        guard let context = modelContext else {
            print("ModelContext was nil, cannot save.")
            return
        }

        do {
            try context.save()
            WidgetCenter.shared.reloadTimelines(ofKind: "FinlineWidget")
        } catch {
            print("Error saving task completion: \(error.localizedDescription)")
        }
    }

    @MainActor
    func appendNewGoal(_ goal: Goal) {
        self.goals.append(goal)
        self.goals.sort { $0.due < $1.due }
    }

    @MainActor
    func appendNewTasks(_ tasks: [GoalTask]) {
        self.tasks.append(contentsOf: tasks)
        print("Added \(tasks.count) new tasks to MainViewModel")
    }

    func filterTasksByDate(for date: Date) -> [GoalTask] {
        let dateTasks = tasks.filter { task in
            Calendar.current.isDate(task.workingTime, inSameDayAs: date)
        }

        switch taskFilter {
        case .all:
            return dateTasks
        case .unfinished:
            return dateTasks.filter { !$0.isCompleted }
        case .finished:
            return dateTasks.filter { $0.isCompleted }
        }
    }

    func filterGoalsByDate(for date: Date) -> [Goal] {
        goals.filter { goal in
            goal.tasks.contains { task in
                Calendar.current.isDate(task.workingTime, inSameDayAs: date)
            }
        }
    }

    // sorting goals based on earliest unfinished task for the date
    func sortedGoals(for date: Date) -> [Goal] {
        let filteredGoals = filterGoalsByDate(for: date)
        let filteredTasks = filterTasksByDate(for: date)

        return filteredGoals.sorted { goal1, goal2 in
            let goal1Tasks = filteredTasks.filter { task in
                goal1.tasks.contains(where: { $0.id == task.id })
            }
            let goal2Tasks = filteredTasks.filter { task in
                goal2.tasks.contains(where: { $0.id == task.id })
            }

            // select earliest unfinished task for each goal
            let goal1EarliestUnfinished =
                goal1Tasks
                .filter { !$0.isCompleted }
                .min(by: { $0.workingTime < $1.workingTime })

            let goal2EarliestUnfinished =
                goal2Tasks
                .filter { !$0.isCompleted }
                .min(by: { $0.workingTime < $1.workingTime })

            // both goals have unfinished tasks
            if let task1 = goal1EarliestUnfinished,
                let task2 = goal2EarliestUnfinished
            {
                return task1.workingTime < task2.workingTime
            }

            // only goal1 has unfinished task
            if goal1EarliestUnfinished != nil {
                return true
            }

            // only goal2 has unfinished task
            if goal2EarliestUnfinished != nil {
                return false
            }

            // both goals have all tasks completed, compare by earliest task
            let goal1Earliest = goal1Tasks.min(by: {
                $0.workingTime < $1.workingTime
            })
            let goal2Earliest = goal2Tasks.min(by: {
                $0.workingTime < $1.workingTime
            })

            if let task1 = goal1Earliest, let task2 = goal2Earliest {
                return task1.workingTime < task2.workingTime
            }

            return goal1.name < goal2.name
        }
    }

    func sortedTasks(for goal: Goal, on date: Date) -> [GoalTask] {
        let filteredTasks = filterTasksByDate(for: date)

        return
            filteredTasks
            .filter { task in
                goal.tasks.contains(where: { $0.id == task.id })
            }
            .sorted {
                if $0.isCompleted == $1.isCompleted {
                    return $0.workingTime < $1.workingTime
                }
                return !$0.isCompleted
            }
    }

    var unfinishedTasks: [GoalTask] {
        tasks.filter { task in
            task.workingTime < Calendar.current.startOfDay(for: Date())
                && !task.isCompleted
        }
    }

    func updateSelectedDate(_ date: Date) {
        DispatchQueue.main.async {
            self.selectedDate = date
        }
    }
}
