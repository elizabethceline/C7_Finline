//
//  AITaskGeneratorViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import SwiftUI
import FoundationModels
import Combine

@MainActor
final class AITaskGeneratorViewModel: ObservableObject {
    @Published var generatedTasks: [AIGoalTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let model = SystemLanguageModel.default

    func generateTasks(for goal: Goal) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard model.isAvailable else {
            errorMessage = "On-device model not available."
            return
        }

        let session = LanguageModelSession(model: model,
                                           instructions: "You are an AI productivity assistant. Return only structured JSON matching AIGoalTask or an array of them.")

        let dateFormatter = ISO8601DateFormatter()
        let todayString = dateFormatter.string(from: Date())
        let prompt = """
            The user has a goal:
            - Title: \(goal.name)
            - Description: \(goal.goalDescription ?? "No description provided")
            - Deadline: \(dateFormatter.string(from: goal.due))
            - Current date: \(todayString)

        Generate 3 to 5 milestone tasks (AIGoalTask) that help achieve this goal before the deadline.
        Each task must follow the AIGoalTask schema (name, workingTime, focusDuration 45-120, isCompleted:false).
        Return either a JSON array of AIGoalTask or a single AIGoalTask (prefer array).
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
                self.generatedTasks = tasks
            }

        } catch {
            errorMessage = "AI generation failed: \(error.localizedDescription)"
        }
    }
}
