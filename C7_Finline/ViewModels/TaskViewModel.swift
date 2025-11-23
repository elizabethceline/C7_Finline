//
//  AITaskGeneratorViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import Combine
import FoundationModels
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [AIGoalTask] = []
    @Published var goalTasks: [GoalTask] = []
    @Published var productiveHours: [ProductiveHours] = []
    @Published var username: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let taskManager: TaskManager
    private let networkMonitor: NetworkMonitor
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.taskManager = TaskManager(networkMonitor: networkMonitor)
    }
    
    private let model = SystemLanguageModel.default
    
    func loadUserProfile(modelContext: ModelContext) async {
        do {
            guard CloudKitManager.shared.isSignedInToiCloud else {
                print("User not signed in to iCloud")
                return
            }
            
            let userRecordID = try await CloudKitManager.shared.fetchUserRecordID()
            let profileManager = UserProfileManager(networkMonitor: networkMonitor)
            let profile = try await profileManager.fetchProfile(
                userRecordID: userRecordID,
                modelContext: modelContext
            )
            
            self.username = profile.username
            
            if let data = profile.productiveHoursJSON.data(using: .utf8) {
                do {
                    let hours = try JSONDecoder().decode([ProductiveHours].self, from: data)
                    self.productiveHours = hours
                } catch {
                    self.productiveHours = DayOfWeek.allCases.map { ProductiveHours(day: $0) }
                    print("Failed to decode productive hours: \(error)")
                }
            } else {
                self.productiveHours = DayOfWeek.allCases.map { ProductiveHours(day: $0) }
            }
            
            print("Loaded user profile: \(self.username)")
            print("Productive Hours:")
            for ph in productiveHours {
                print("\(ph.day): \(ph.timeSlots) hours")
            }
            
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    //saved to Swift Data
    func createAllGoalTasks(for goal: Goal, modelContext: ModelContext) async {
        guard !tasks.isEmpty else {
            print("No generated tasks to save.")
            return
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        for task in tasks {
            guard let workingDate = dateFormatter.date(from: task.workingTime)
            else {
                print("Invalid workingTime: \(task.workingTime)")
                continue
            }
            
            _ = taskManager.createTask(
                goal: goal,
                name: task.name,
                workingTime: workingDate,
                focusDuration: task.focusDuration,
                modelContext: modelContext
            )
        }
        
        do {
            try modelContext.save()
            print("Saved \(tasks.count) AI tasks for goal \(goal.name)")
            
            WidgetCenter.shared.reloadTimelines(ofKind: "FinlineWidget")
            
        } catch {
            print("Failed to save AI tasks: \(error.localizedDescription)")
        }
    }
    
    func getGoalTaskByGoalId(for goal: Goal, modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        
        let goalId = goal.id
        
        let descriptor = FetchDescriptor<GoalTask>(
            predicate: #Predicate { task in
                task.goal?.id == goalId
            },
            sortBy: [SortDescriptor(\.workingTime, order: .forward)]
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            await MainActor.run {
                self.goalTasks = results
                print(
                    "Successfully fetched \(results.count) tasks for goal \(goal.name)"
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage =
                "Failed to fetch tasks: \(error.localizedDescription)"
                print(
                    "Error fetching tasks for goal \(goal.name): \(error.localizedDescription)"
                )
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func updateGoalTask(
        _ task: GoalTask,
        name: String,
        workingTime: Date,
        focusDuration: Int,
        isCompleted: Bool,
        modelContext: ModelContext
    ) async {
        taskManager.updateTask(
            task: task,
            name: name,
            workingTime: workingTime,
            focusDuration: focusDuration,
            isCompleted: isCompleted
        )
        
        do {
            try modelContext.save()
            print("Task '\(name)' updated successfully.")
            
            WidgetCenter.shared.reloadTimelines(ofKind: "FinlineWidget")
            
        } catch {
            print("Failed to save updated task: \(error.localizedDescription)")
        }
    }
    
    func deleteGoalTask(_ task: GoalTask, modelContext: ModelContext) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            taskManager.deleteTask(task: task, modelContext: modelContext)
            
            try modelContext.save()
            
            WidgetCenter.shared.reloadTimelines(ofKind: "FinlineWidget")
            
            await MainActor.run {
                self.goalTasks.removeAll { $0.id == task.id }
                print("Deleted task: \(task.name)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage =
                "Failed to delete task: \(error.localizedDescription)"
                print(
                    "Error deleting task '\(task.name)': \(error.localizedDescription)"
                )
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    //temporary CRUD before saved to Swift Data
    func createTaskManually(name: String, workingTime: Date, focusDuration: Int)
    {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Task name cannot be empty."
            return
        }
        
        guard focusDuration > 0 else {
            errorMessage = "Focus duration must be greater than 0."
            return
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let formattedTime = dateFormatter.string(from: workingTime)
        
        guard !formattedTime.isEmpty else {
            errorMessage = "Failed to format working time."
            return
        }
        
        let newTask = AIGoalTask(
            name: name,
            workingTime: formattedTime,
            focusDuration: focusDuration,
            isCompleted: false
        )
        
        tasks.append(newTask)
        sortTasksByDate()
        errorMessage = nil
        print("Task '\(name)' created successfully.")
    }
    
    func updateTask(
        _ task: AIGoalTask,
        name: String,
        workingTime: String,
        focusDuration: Int
    ) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Task name cannot be empty."
            return
        }
        
        guard !workingTime.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Working time cannot be empty."
            return
        }
        
        guard focusDuration > 0 else {
            errorMessage = "Focus duration must be greater than 0."
            return
        }
        
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            errorMessage = "Task not found for update."
            return
        }
        
        tasks[index].name = name
        tasks[index].workingTime = workingTime
        tasks[index].focusDuration = focusDuration
        
        errorMessage = nil
        print("Task '\(name)' updated successfully.")
    }
    
    func deleteTask(_ task: AIGoalTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
            print("Task deleted: \(task.name)")
        } else {
            print("Task not found for deletion")
        }
    }
    //Create Task on Goal Detail View
    func createTaskForGoal(
        goalId: String,
        name: String,
        workingTime: Date,
        focusDuration: Int,
        modelContext: ModelContext
    ) async {
        let goalPredicate = #Predicate<Goal> { $0.id == goalId }
        guard let goal = try? modelContext.fetch(
            FetchDescriptor(predicate: goalPredicate)
        ).first else {
            print("Goal not found")
            return
        }
        
        print("Found goal: \(goal.name)")
        
        let newTask = taskManager.createTask(
            goal: goal,
            name: name,
            workingTime: workingTime,
            focusDuration: focusDuration,
            modelContext: modelContext
        )
        print("Created task: \(newTask.name) for goal: \(goal.name)")
        print("Goal now has \(goal.tasks.count) tasks")
        
        do {
            try modelContext.save()
            print("Context saved successfully")
            
            WidgetCenter.shared.reloadTimelines(ofKind: "FinlineWidget")
            
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    private func sortTasksByDate() {
        let dateFormatter = ISO8601DateFormatter()
        tasks.sort { t1, t2 in
            guard let d1 = dateFormatter.date(from: t1.workingTime),
                  let d2 = dateFormatter.date(from: t2.workingTime)
            else {
                return false
            }
            return d1 < d2
        }
    }
    
    func generateTaskWithAI(
        for goalName: String,
        goalDescription: String,
        goalDeadline: Date
    ) async {
        await MainActor.run {
            self.tasks.removeAll()
        }
        
        let goal = Goal(
            id: UUID().uuidString,
            name: goalName,
            due: goalDeadline,
            goalDescription: goalDescription
        )
        await prompt(for: goal)
    }
    
    func prompt(for goal: Goal) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard model.isAvailable else {
            errorMessage = "On-device model not available."
            return
        }
        
        let session = LanguageModelSession(model: model)
        print(productiveHours)
        
        let totalMinutesAvailable: Int = Int(goal.due.timeIntervalSinceNow / 60)
        let totalTask: Int = totalMinutesAvailable < 1440 ? 2 : 5
        
        let prompt = """
        You are an AI productivity assistant.
        
        Goal Title: \(goal.name)
        Description: \(goal.goalDescription ?? "No description provided")
        
        Generate exactly \(totalTask) tasks.
        Each must contain:
        - "name": unique descriptive title
        - "focusDuration": duration in minutes
            Easy: 20–30
            Medium: 30–60
            Hard: 60–120
        
        RULES:
        - DO NOT generate date/time.
        - DO NOT include start/end times.
        - Total focus duration must NOT exceed \(totalMinutesAvailable) minutes.
        Return ONLY JSON array of { "name": "...", "focusDuration": ... }
        """
        
        var aiItems: [AIPlannedItem] = []
        do {
            let response = try await session.respond(
                to: prompt,
                generating: [AIPlannedItem].self
            )
            aiItems = response.content
        } catch {
            errorMessage = "Failed to parse AI tasks: \(error.localizedDescription)"
            return
        }
        
        await mapWorkingTimes(from: aiItems, deadline: goal.due)
    }
    
    func mapWorkingTimes(
        from items: [AIPlannedItem],
        deadline: Date
    ) async {
        let iso = ISO8601DateFormatter()
        var currentTime = Date()
        var usedMinutes = 0
        
        await MainActor.run { self.tasks = [] }
        
        for item in items {
            if usedMinutes + item.focusDuration > Int(deadline.timeIntervalSinceNow / 60) {
                break
            }
            
            guard let nextSlot = nextAvailableProductiveSlot(from: currentTime, duration: item.focusDuration) else {
                print("No available productive slot found for remaining time")
                break
            }
            
            let taskStart = nextSlot.start
            let taskEnd = nextSlot.end
            
            let task = AIGoalTask(
                name: item.name,
                workingTime: iso.string(from: taskStart),
                focusDuration: item.focusDuration
            )
            
            await MainActor.run { self.tasks.append(task) }
            
            usedMinutes += item.focusDuration
            currentTime = taskEnd.addingTimeInterval(15 * 60)
        }
    }
    
    private func nextAvailableProductiveSlot(from date: Date, duration: Int) -> (start: Date, end: Date)? {
        let cal = Calendar.current
        var currentDate = date
        
        for _ in 0..<30 {
            let dayOfWeek = DayOfWeek.from(date: currentDate)
            guard let dayHours = productiveHours.first(where: { $0.day == dayOfWeek }), !dayHours.timeSlots.isEmpty else {
                currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
                continue
            }
            
            let sortedSlots = dayHours.timeSlots.sorted { $0.order < $1.order }
            
            for slot in sortedSlots {
                let slotRange = timeRange(for: slot, on: currentDate)
                let slotStart = max(currentDate, slotRange.start)
                let slotEnd = slotRange.end
                let slotMinutes = Int(slotEnd.timeIntervalSince(slotStart) / 60)
                
                if slotMinutes >= duration {
                    return (start: slotStart, end: slotStart.addingTimeInterval(Double(duration) * 60))
                }
            }
            
            currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
            currentDate = cal.date(bySettingHour: 0, minute: 0, second: 0, of: currentDate)!
        }
        
        return nil
    }
    
    
    
    private func timeRange(for slot: TimeSlot, on date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch slot {
        case .earlyMorning:
            return (
                start: cal.date(bySettingHour: 0, minute: 0, second: 0, of: date)!,
                end: cal.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
            )
        case .morning:
            return (
                start: cal.date(bySettingHour: 8, minute: 0, second: 0, of: date)!,
                end: cal.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
            )
        case .afternoon:
            return (
                start: cal.date(bySettingHour: 12, minute: 0, second: 0, of: date)!,
                end: cal.date(bySettingHour: 17, minute: 0, second: 0, of: date)!
            )
        case .evening:
            return (
                start: cal.date(bySettingHour: 17, minute: 0, second: 0, of: date)!,
                end: cal.date(bySettingHour: 21, minute: 0, second: 0, of: date)!
            )
        case .night:
            return (
                start: cal.date(bySettingHour: 21, minute: 0, second: 0, of: date)!,
                end: cal.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
            )
        }
    }
    
}

extension DayOfWeek {
    static func from(date: Date) -> DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

extension TaskViewModel {
    
    var groupedPendingGoalTasks: [(date: Date, tasks: [GoalTask])] {
        let pendingTasks = goalTasks
        let grouped = Dictionary(grouping: pendingTasks) { task in
            Calendar.current.startOfDay(for: task.workingTime)
        }
        return
        grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, tasks: $0.value) }
    }
    
    var groupedGoalTasks: [(date: Date, tasks: [GoalTask])] {
        let grouped = Dictionary(grouping: goalTasks) { task in
            Calendar.current.startOfDay(for: task.workingTime)
        }
        return
        grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, tasks: $0.value) }
    }
    
    func groupedGoalTaskAI() -> [(date: Date, tasks: [AIGoalTask])] {
        let dateFormatter = ISO8601DateFormatter()
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: tasks) { task -> Date in
            if let date = dateFormatter.date(from: task.workingTime) {
                return calendar.startOfDay(for: date)
            } else {
                return calendar.startOfDay(for: Date())
            }
        }
        
        return
        grouped
            .sorted { $0.key < $1.key }
            .map {
                (
                    date: $0.key,
                    tasks: $0.value.sorted {
                        guard
                            let d1 = dateFormatter.date(from: $0.workingTime),
                            let d2 = dateFormatter.date(from: $1.workingTime)
                        else { return false }
                        return d1 < d2
                    }
                )
            }
    }
    
    func toGoalTask(
        from aiTask: AIGoalTask,
        workingDate: Date,
        goalName: String,
        goalDeadline: Date
    ) -> GoalTask {
        GoalTask(
            id: aiTask.id,
            name: aiTask.name,
            workingTime: workingDate,
            focusDuration: aiTask.focusDuration,
            isCompleted: false,
            goal: Goal(
                id: "temp_goal",
                name: goalName,
                due: goalDeadline,
                goalDescription: ""
            )
        )
    }
}
