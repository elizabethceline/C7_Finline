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
    @Published var existingTasks: [GoalTask] = []
    private let taskManager: TaskManager
    private let networkMonitor: NetworkMonitor
    
    
    init(networkMonitor: NetworkMonitor = .shared) {
        self.networkMonitor = networkMonitor
        self.taskManager = TaskManager(networkMonitor: networkMonitor)
    }
    
    private let model = SystemLanguageModel.default
    
    func loadUserProfile(modelContext: ModelContext) async {
        do {
            guard CloudKitManager.shared.isSignedInToiCloud else {
                print("User not signed in to iCloud, loading from SwiftData")
                await loadProductiveHoursFromSwiftData(modelContext: modelContext)
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
            
            print("Loaded user profile from iCloud: \(self.username)")
            print("Productive Hours:")
            for ph in productiveHours {
                print("\(ph.day): \(ph.timeSlots) hours")
            }
            
        } catch {
            print("Error loading user profile from iCloud: \(error)")
            await loadProductiveHoursFromSwiftData(modelContext: modelContext)
        }
    }
    
    private func loadProductiveHoursFromSwiftData(modelContext: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            
            if let localProfile = profiles.first {
                self.username = localProfile.username
                if let data = localProfile.productiveHoursJSON.data(using: .utf8) {
                    do {
                        let hours = try JSONDecoder().decode([ProductiveHours].self, from: data)
                        self.productiveHours = hours
                        print("Loaded productive hours from SwiftData")
                    } catch {
                        self.productiveHours = DayOfWeek.allCases.map { ProductiveHours(day: $0) }
                        print("Failed to decode productive hours from SwiftData: \(error)")
                    }
                } else {
                    self.productiveHours = DayOfWeek.allCases.map { ProductiveHours(day: $0) }
                }
                
                print("Loaded user profile from SwiftData: \(self.username)")
                print("Productive Hours:")
                for ph in productiveHours {
                    print("\(ph.day): \(ph.timeSlots) hours")
                }
            } else {
                print("No local profile found, using default productive hours")
                self.productiveHours = DayOfWeek.allCases.map { ProductiveHours(day: $0) }
                self.username = "User"
            }
        } catch {
            print("Error loading productive hours from SwiftData: \(error)")
            self.productiveHours = DayOfWeek.allCases.map { ProductiveHours(day: $0) }
            self.username = "User"
        }
    }
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
    
    func createTaskForGoal(
        goalId: String,
        name: String,
        workingTime: Date,
        focusDuration: Int,
        modelContext: ModelContext
    ) async {
        let goalPredicate = #Predicate<Goal> { $0.id == goalId }
        guard
            let goal = try? modelContext.fetch(
                FetchDescriptor(predicate: goalPredicate)
            ).first
        else {
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
    
    func calculateAvailableMinutes(from startDate: Date, to endDate: Date) async -> Int {
        return calculateProductiveMinutes(from: startDate, to: endDate)
    }
    
    func hasProductiveHours() -> Bool {
        return productiveHours.contains { !$0.timeSlots.isEmpty }
    }
    
    func generateTaskWithAI(
        for goalName: String,
        goalDescription: String,
        goalDeadline: Date,
        ignoreTimeLimit: Bool = false,
        modelContext: ModelContext
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
        await prompt(for: goal, ignoreTimeLimit: ignoreTimeLimit, modelContext: modelContext)
    }
    
    func prompt(for goal: Goal, ignoreTimeLimit: Bool = false, modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard model.isAvailable else {
            errorMessage = "On-device model not available."
            return
        }
        
        await loadExistingTasks(from: Date(), to: goal.due, modelContext: modelContext)
        
        let session = LanguageModelSession(model: model)
        print("Productive hours: \(productiveHours)")
        print("Existing tasks count: \(existingTasks.count)")
        
        let hasProductiveHours = self.hasProductiveHours()
        print("Has productive hours: \(hasProductiveHours)")
        
        let totalMinutesAvailable = calculateProductiveMinutes(from: Date(), to: goal.due)
        print("Total minutes available: \(totalMinutesAvailable)")
        
        let totalTask: Int
        let timeConstraint: String
        
        if ignoreTimeLimit {
            totalTask = 5
            timeConstraint = "Generate tasks without strict time constraints."
        } else {
            totalTask = totalMinutesAvailable < 500 ? 2 : 5
            timeConstraint = hasProductiveHours
            ? "Total focus duration must NOT exceed \(totalMinutesAvailable) minutes based on productive hours."
            : "Total focus duration must fit within \(totalMinutesAvailable) minutes from now until deadline."
        }
        print("ignore time limit  \(ignoreTimeLimit)")
        print("total Minutes Avail \(totalMinutesAvailable)")
        
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
            - \(timeConstraint)
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
        
        await mapWorkingTimes(from: aiItems, deadline: goal.due, ignoreTimeLimit: ignoreTimeLimit)
    }
    
    private func loadExistingTasks(from startDate: Date, to endDate: Date, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<GoalTask>(
            predicate: #Predicate { task in
                task.workingTime >= startDate && task.workingTime <= endDate
            },
            sortBy: [SortDescriptor(\.workingTime, order: .forward)]
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            await MainActor.run {
                self.existingTasks = results
                print("Loaded \(results.count) existing tasks in range \(startDate) to \(endDate)")
                for task in results {
                    print("  - \(task.name) at \(task.workingTime)")
                }
            }
        } catch {
            print("Error loading existing tasks: \(error.localizedDescription)")
            await MainActor.run {
                self.existingTasks = []
            }
        }
    }
    
    private func isTimeSlotAvailable(start: Date, end: Date) -> Bool {
        for existingTask in existingTasks {
            let taskStart = existingTask.workingTime
            let taskEnd = taskStart.addingTimeInterval(Double(existingTask.focusDuration) * 60)
            
            if start < taskEnd && end > taskStart {
                print("⚠️ Conflict detected:")
                print("  New slot: \(start) - \(end)")
                print("  Existing task: '\(existingTask.name)' at \(taskStart) - \(taskEnd)")
                return false
            }
        }
        return true
    }
    
    
    private func calculateProductiveMinutes(from startDate: Date, to endDate: Date) -> Int {
        let hasAnyProductiveHours = productiveHours.contains { !$0.timeSlots.isEmpty }
        
        if !hasAnyProductiveHours {
            let totalMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
            print("No productive hours set, using full time range: \(totalMinutes) minutes")
            return max(0, totalMinutes)
        }
        
        let cal = Calendar.current
        var currentDate = startDate
        var totalMinutes = 0
        
        var daysChecked = 0
        let maxDays = 365
        
        while currentDate < endDate && daysChecked < maxDays {
            let dayOfWeek = DayOfWeek.from(date: currentDate)
            guard let dayHours = productiveHours.first(where: { $0.day == dayOfWeek }),
                  !dayHours.timeSlots.isEmpty else {
                currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
                currentDate = cal.startOfDay(for: currentDate)
                daysChecked += 1
                continue
            }
            
            for slot in dayHours.timeSlots {
                let slotRange = timeRange(for: slot, on: currentDate)
                
                let actualStart = max(startDate, slotRange.start)
                let actualEnd = min(endDate, slotRange.end)
                
                if actualStart < actualEnd {
                    let slotMinutes = Int(actualEnd.timeIntervalSince(actualStart) / 60)
                    totalMinutes += slotMinutes
                }
            }
            
            currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
            currentDate = cal.startOfDay(for: currentDate)
            daysChecked += 1
        }
        
        return totalMinutes
    }
    
    func mapWorkingTimes(
        from items: [AIPlannedItem],
        deadline: Date,
        ignoreTimeLimit: Bool = false
    ) async {
        let iso = ISO8601DateFormatter()
        var currentTime = Date()
        var usedMinutes = 0
        
        await MainActor.run { self.tasks = [] }
        
        let hasAnyProductiveHours = productiveHours.contains { !$0.timeSlots.isEmpty }
        
        for item in items {
            if !ignoreTimeLimit && usedMinutes + item.focusDuration > Int(deadline.timeIntervalSinceNow / 60) {
                print("Task would exceed time limit, stopping generation")
                break
            }
            
            let taskStart: Date
            let taskEnd: Date
            
            if hasAnyProductiveHours {
                guard let nextSlot = nextAvailableProductiveSlot(from: currentTime, duration: item.focusDuration) else {
                    print("No available productive slot found for remaining time")
                    break
                }
                taskStart = nextSlot.start
                taskEnd = nextSlot.end
            } else {
                taskStart = currentTime
                taskEnd = currentTime.addingTimeInterval(Double(item.focusDuration) * 60)
                
                if taskEnd > deadline {
                    print("Task would exceed deadline, stopping generation")
                    break
                }
            }
            
            let task = AIGoalTask(
                name: item.name,
                workingTime: iso.string(from: taskStart),
                focusDuration: item.focusDuration
            )
            
            await MainActor.run { self.tasks.append(task) }
            
            usedMinutes += item.focusDuration
            currentTime = taskEnd.addingTimeInterval(15 * 60)
        }
        
        print("Generated \(tasks.count) tasks, total duration: \(usedMinutes) minutes")
    }
    
    private func nextAvailableProductiveSlot(from date: Date, duration: Int) -> (start: Date, end: Date)? {
        let hasAnyProductiveHours = productiveHours.contains { !$0.timeSlots.isEmpty }
        
        if !hasAnyProductiveHours {
            print("No productive hours set, scheduling task immediately")
            var currentTime = date
            let taskEnd = currentTime.addingTimeInterval(Double(duration) * 60)
            
            while !isTimeSlotAvailable(start: currentTime, end: taskEnd) {
                if let conflictingTask = existingTasks.first(where: { task in
                    let taskStart = task.workingTime
                    let taskEnd = taskStart.addingTimeInterval(Double(task.focusDuration) * 60)
                    return currentTime < taskEnd && taskEnd > taskStart
                }) {
                    currentTime = conflictingTask.workingTime.addingTimeInterval(Double(conflictingTask.focusDuration + 15) * 60)
                } else {
                    break
                }
            }
            
            return (start: currentTime, end: currentTime.addingTimeInterval(Double(duration) * 60))
        }
        
        let cal = Calendar.current
        var currentDate = date
        
        for _ in 0..<30 {
            let dayOfWeek = DayOfWeek.from(date: currentDate)
            guard let dayHours = productiveHours.first(where: { $0.day == dayOfWeek }),
                  !dayHours.timeSlots.isEmpty else {
                currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
                continue
            }
            
            let sortedSlots = dayHours.timeSlots.sorted { $0.order < $1.order }
            
            for slot in sortedSlots {
                let slotRange = timeRange(for: slot, on: currentDate)
                var slotStart = max(currentDate, slotRange.start)
                let slotEnd = slotRange.end
                
                while slotStart.addingTimeInterval(Double(duration) * 60) <= slotEnd {
                    let taskEnd = slotStart.addingTimeInterval(Double(duration) * 60)
                    
                    if isTimeSlotAvailable(start: slotStart, end: taskEnd) {
                        return (start: slotStart, end: taskEnd)
                    }
                    if let conflictingTask = existingTasks.first(where: { task in
                        let taskStart = task.workingTime
                        let taskEnd = taskStart.addingTimeInterval(Double(task.focusDuration) * 60)
                        return slotStart < taskEnd && taskEnd > taskStart
                    }) {
                        slotStart = conflictingTask.workingTime.addingTimeInterval(Double(conflictingTask.focusDuration + 15) * 60)
                    } else {
                        slotStart = slotStart.addingTimeInterval(15 * 60)
                    }
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
        return grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, tasks: $0.value) }
    }
    
    var groupedGoalTasks: [(date: Date, tasks: [GoalTask])] {
        let grouped = Dictionary(grouping: goalTasks) { task in
            Calendar.current.startOfDay(for: task.workingTime)
        }
        return grouped
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
        
        return grouped
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
