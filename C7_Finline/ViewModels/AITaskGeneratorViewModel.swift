//
//  AITaskGeneratorViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import Foundation
import SwiftUI
import Observation
import FoundationModels

@Observable
class AIViewModel {
    private let model = SystemLanguageModel.default

    private func makeSession(instructions: String? = nil) -> LanguageModelSession {
        if let instructions = instructions {
            return LanguageModelSession(model: model, instructions: instructions)
        } else {
            return LanguageModelSession(model: model)
        }
    }

    @MainActor
    func generateTasks() async throws -> [String] {
        guard model.isAvailable else {
            throw NSError(
                domain: "AIViewModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "SystemLanguageModel is not available on this device."]
            )
        }
        
        //prewarm
        //AI temperature
        
        let goal = "creating UI UX designs for news websites"
        let deadline = "2025-10-27 17:00"
        let currentDateTime = "2025-10-23 22:00"
        let productiveHoursStart = "08:00"
        let productiveHoursEnd = "17:00"
        let productiveDays = "Monday–Friday"

        let systemPrompt = """
        You are a productivity assistant that helps users break a goal into realistic, achievable tasks.

        Goal: \(goal)
        Deadline: \(deadline)
        Current time: \(currentDateTime)
        Productive hours: \(productiveHoursStart)–\(productiveHoursEnd)
        Productive days: \(productiveDays)

        Generate exactly 5 chronological tasks that meet ALL of the following constraints:

        1. Tasks do NOT need to be completed all in one day. They can be distributed across multiple days as long as they finish before the deadline (\(deadline)).
        2. Each task must start **no earlier than \(productiveHoursStart)** and **end no later than \(productiveHoursEnd)** on the same day.
        3. If the current time (\(currentDateTime)) is outside productive hours, schedule the first task at the next available productive time (e.g., next weekday at \(productiveHoursStart)).
        4. Only schedule tasks on weekdays (\(productiveDays)). Never schedule tasks on Saturday or Sunday.
        5. Tasks must occur sequentially without overlap and should make chronological sense.
        6. Allow realistic breaks or gaps between tasks (e.g., 10–20 minutes).
        7. All tasks must finish before the deadline (\(deadline)).

        For each task, include:
        - Task number (1., 2., etc.)
        - Task title
        - Scheduled date and time range (e.g., "2025-10-24 09:00–10:00")
        - Focus duration (in minutes):
            - Short/simple: 25–40
            - Medium: 45–60
            - Long/complex: 75–90

        Output format:
        1. [Task title] — [Date] [Start–End time], [Focus duration] mins
        2. ...
        """

        let session = makeSession(instructions: "You are a structured assistant. Reply strictly in the requested format.")

        let response = try await session.respond(to: systemPrompt)
        let resultText: String = String(describing: response)
        let rawLines = resultText.components(separatedBy: CharacterSet.newlines)
        let tasks = rawLines
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return tasks
    }
}
