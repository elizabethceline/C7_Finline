//
//  MainViewModel.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import Combine
import Foundation
import SwiftData

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

    @MainActor
    var isSignedInToiCloud: Bool {
        CloudKitManager.shared.isSignedInToiCloud
    }

    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.goalManager = GoalManager(networkMonitor: networkMonitor)
        self.taskManager = TaskManager(networkMonitor: networkMonitor)

        observeNetworkStatus()
    }

    @MainActor
    func setModelContext(_ context: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = context

        loadDataFromSwiftData()
        print("Local data loaded: \(goals.count) goals, \(tasks.count) tasks")

        Task {
            if networkMonitor.isConnected,
                isSignedInToiCloud
            {
                isLoading = true
                let cloudGoals = try? await goalManager.fetchGoals(
                    modelContext: context
                )
                if let cloudGoals = cloudGoals {
                    updatePublishedGoals(cloudGoals)
                    try? context.save()
                    await fetchAllTasks()
                    print("Fetched \(cloudGoals.count) goals from CloudKit")
                }
                isLoading = false

                print("Sync pending local changes...")
                await syncPendingItems()

                print("Refresh cloud tasks & goals")
                await fetchGoals()
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
                        await self.syncPendingItems()
                        await self.fetchGoals()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // load data
    @MainActor
    private func loadDataFromSwiftData() {
        guard let modelContext = modelContext else { return }

        do {
            // Load goals
            let goalDescriptor = FetchDescriptor<Goal>(
                sortBy: [SortDescriptor(\.due, order: .forward)]
            )
            let taskDescriptor = FetchDescriptor<GoalTask>()

            let localGoals = try modelContext.fetch(goalDescriptor)
            let localTasks = try modelContext.fetch(taskDescriptor)

            updatePublishedGoals(localGoals)
            updatePublishedTasks(localTasks)
        } catch {
            self.error =
                "Failed to load local data: \(error.localizedDescription)"
        }
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

    // CRUD Goal
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
    }

    @MainActor
    func toggleTaskCompletion(task: GoalTask) {
        taskManager.toggleTaskCompletion(task: task)
    }

    func syncPendingItems() async {
        guard let modelContext = modelContext, networkMonitor.isConnected else {
            return
        }

        // Sync deletions
        await goalManager.syncPendingDeletions()
        await taskManager.syncPendingDeletions()

        // Sync goals
        await goalManager.syncPendingGoals(modelContext: modelContext)

        // Sync tasks
        await taskManager.syncPendingTasks(modelContext: modelContext)
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
            let goal1EarliestUnfinished = goal1Tasks
                .filter { !$0.isCompleted }
                .min(by: { $0.workingTime < $1.workingTime })
            
            let goal2EarliestUnfinished = goal2Tasks
                .filter { !$0.isCompleted }
                .min(by: { $0.workingTime < $1.workingTime })
            
            // both goals have unfinished tasks
            if let task1 = goal1EarliestUnfinished, let task2 = goal2EarliestUnfinished {
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
            let goal1Earliest = goal1Tasks.min(by: { $0.workingTime < $1.workingTime })
            let goal2Earliest = goal2Tasks.min(by: { $0.workingTime < $1.workingTime })
            
            if let task1 = goal1Earliest, let task2 = goal2Earliest {
                return task1.workingTime < task2.workingTime
            }
            
            return goal1.name < goal2.name
        }
    }
    
    func sortedTasks(for goal: Goal, on date: Date) -> [GoalTask] {
        let filteredTasks = filterTasksByDate(for: date)
        
        return filteredTasks
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
