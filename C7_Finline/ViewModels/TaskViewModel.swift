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

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [AIGoalTask] = []
    @Published var goalTasks: [GoalTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let taskManager: TaskManager
    private let networkMonitor: NetworkMonitor

    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.taskManager = TaskManager(networkMonitor: networkMonitor)
    }

    private let model = SystemLanguageModel.default

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

        //dummy
        let user = UserProfile(
            id: "user-1",
            username: "Elizabeth",
            points: 200,
            productiveHours: [
                ProductiveHours(
                    day: .monday,
                    timeSlots: [.morning, .afternoon]
                ),
                ProductiveHours(
                    day: .tuesday,
                    timeSlots: [.morning, .evening]
                ),
                ProductiveHours(day: .wednesday, timeSlots: [.afternoon]),
                ProductiveHours(
                    day: .thursday,
                    timeSlots: [.morning, .afternoon]
                ),
                ProductiveHours(day: .friday, timeSlots: [.morning]),
                ProductiveHours(
                    day: .saturday,
                    timeSlots: [.morning, .evening]
                ),
                ProductiveHours(day: .sunday, timeSlots: [.evening]),
            ]

        )

        guard model.isAvailable else {
            errorMessage = "On-device model not available."
            return
        }

        let session = LanguageModelSession(
            model: model,
            instructions:
                "You are an AI productivity assistant. Return only structured JSON matching AIGoalTask or an array of them."
        )

        let dateFormatter = ISO8601DateFormatter()
        let todayString = dateFormatter.string(from: Date())

        let productiveDaysDescription = user.productiveHours.map { ph in
            let day = ph.day.rawValue.capitalized
            let slots = ph.timeSlots.map { slot -> [String: String] in
                switch slot {
                case .earlyMorning: return ["start": "04:00", "end": "08:00"]
                case .morning: return ["start": "08:00", "end": "12:00"]
                case .afternoon: return ["start": "12:00", "end": "17:00"]
                case .evening: return ["start": "17:00", "end": "21:00"]
                case .night: return ["start": "21:00", "end": "24:00"]
                }
            }
            let slotsJSON = slots.map { "\($0["start"]!)-\($0["end"]!)" }
                .joined(separator: ", ")
            return "- \(day): \(slotsJSON)"
        }.joined(separator: "\n")

        print("=== Productive Hours Description ===")
        print(productiveDaysDescription)
        print("===================================")

        print(goal.due)
        print(todayString)
        let prompt = """
            You are an AI productivity assistant that creates actionable milestone tasks for a user's goal.

            ## USER PROFILE
            - Name: \(user.username)
            - Productive Hours:
            \(productiveDaysDescription)

            ## GOAL
            - Title: \(goal.name)
            - Description: \(goal.goalDescription ?? "No description provided")
            - Deadline: \(dateFormatter.string(from: goal.due))
            - Current Date: \(todayString)

            ## TASK GENERATION RULES
            1. Generate between 2 and 5 milestone tasks that break the goal into clear, actionable steps. Maximum generate 5 task.
            3. If the time remaining between the current date (\(todayString)) and the goal deadline (\(dateFormatter.string(from: goal.due))) is **less than 24 hours**, generate **only 2 milestone tasks** that can realistically be completed within that limited time.
            4. Each task must include:
                - `name`: Short descriptive title
                - `workingTime`: Start date and time (within productive hours)
                - `focusDuration`: Duration in minutes (45–120)
            5. All tasks must:
                - Start and end **before or exactly at** the goal deadline \(dateFormatter.string(from: goal.due)).
                - Not overlap with each other.
                - Fit strictly within productive hours.
                - Optionally leave 10–15 minutes between tasks.
            6. If time is tight, ensure the last task ends **just before the deadline**, not after.
            7. **If the goal deadline is more than a day ahead of the current time (\(todayString)), spread the tasks across multiple days** based on the available productive hours.  
               - Do **not** stack all tasks on the same day if there is enough time before the deadline.
               - Try to distribute tasks evenly over the days leading up to the deadline.
            8. Return only valid JSON.
            """

        do {
            var tasks: [AIGoalTask] = []

            let response = try await session.respond(
                to: prompt,
                generating: [AIGoalTask].self
            )
            tasks = response.content

            if tasks.isEmpty {
                if let singleResp = try? await session.respond(
                    to: prompt,
                    generating: AIGoalTask.self
                ) {
                    tasks = [singleResp.content]
                }
            }

            if tasks.isEmpty {
                let raw = try await session.respond(to: prompt)
                if let data = raw.content.data(using: .utf8),
                    let decoded = try? JSONDecoder().decode(
                        [AIGoalTask].self,
                        from: data
                    )
                {
                    tasks = decoded
                }
            }

            if tasks.isEmpty {
                errorMessage = "AI returned no valid tasks."
            } else {
                self.tasks = tasks
            }

        } catch {
            errorMessage = "AI generation failed: \(error.localizedDescription)"
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
