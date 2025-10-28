//
//  AITaskGeneratorViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import SwiftUI
import FoundationModels
import Combine
import SwiftData

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [AIGoalTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let taskManager: TaskManager
    private let networkMonitor: NetworkMonitor
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.taskManager = TaskManager(networkMonitor: networkMonitor)
    }
    
    private let model = SystemLanguageModel.default
    
    
    func createAllTasks(for goal: Goal, modelContext: ModelContext) async {
        guard !tasks.isEmpty else {
            print("⚠️ No generated tasks to save.")
            return
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        for task in tasks {
            guard let workingDate = dateFormatter.date(from: task.workingTime) else {
                print("⚠️ Invalid workingTime: \(task.workingTime)")
                continue
            }
            
            _ = taskManager.createTask(
                goalId: goal.id,
                name: task.name,
                workingTime: workingDate,
                focusDuration: task.focusDuration,
                goals: [goal],
                modelContext: modelContext
            )
        }
        
        do {
            try modelContext.save()
            print("✅ Saved \(tasks.count) AI tasks for goal \(goal.name)")
        } catch {
            print("❌ Failed to save AI tasks: \(error.localizedDescription)")
        }
    }
    
    func generate(for goalName: String, goalDescription: String, goalDeadline: Date) async {
        await MainActor.run {
            self.tasks.removeAll()
        }
        
        let goal = Goal(
            id: UUID().uuidString,
            name: goalName,
            due: goalDeadline,
            goalDescription: goalDescription
        )
        await generateTasks(for: goal)
    }
    
    func generateTasks(for goal: Goal) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        //dummy
        let user = UserProfile(
            id: "user-1",
            username: "Elizabeth",
            points: 200,
            productiveHours: [
                ProductiveHours(day: .monday, timeSlots: [.morning, .afternoon]),
                ProductiveHours(day: .tuesday, timeSlots: [.morning, .evening]),
                ProductiveHours(day: .wednesday, timeSlots: [.afternoon]),
                ProductiveHours(day: .thursday, timeSlots: [.morning, .afternoon]),
                ProductiveHours(day: .friday, timeSlots: [.morning]),
                ProductiveHours(day: .saturday, timeSlots: [.morning, .evening]),
                ProductiveHours(day: .sunday, timeSlots: [.evening])
            ]
            
        )
        
        guard model.isAvailable else {
            errorMessage = "On-device model not available."
            return
        }
        
        let session = LanguageModelSession(model: model,
                                           instructions: "You are an AI productivity assistant. Return only structured JSON matching AIGoalTask or an array of them.")
        
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
            let slotsJSON = slots.map { "\($0["start"]!)-\($0["end"]!)" }.joined(separator: ", ")
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
            
            let response = try await session.respond(to: prompt, generating: [AIGoalTask].self)
            tasks = response.content
            
            if tasks.isEmpty {
                if let singleResp = try? await session.respond(to: prompt, generating: AIGoalTask.self) {
                    tasks = [singleResp.content]
                }
            }
            
            if tasks.isEmpty {
                let raw = try await session.respond(to: prompt)
                if let data = raw.content.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode([AIGoalTask].self, from: data) {
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
