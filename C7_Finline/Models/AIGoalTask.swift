//
//  AIGoalTask.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 25/10/25.
//

import Foundation
import FoundationModels

@Generable
struct AIGoalTask: Identifiable, Codable {
    var id: String = UUID().uuidString

    @Guide(description: "A short descriptive name for the task milestone.")
    var name: String

    @Guide(description: "The scheduled working time (Date) within user's productive hours and before goal deadline.")
    var workingTime: String

    @Guide(description: "Focus duration in minutes (45–120).")
    var focusDuration: Int

    @Guide(description: "Whether the task is completed or not. Defaults to false when generated.")
    var isCompleted: Bool = false

//    func toGoalTask(goal: Goal? = nil) -> GoalTask {
//        GoalTask(id: id,
//                 name: name,
//                 workingTime: workingTime,
//                 focusDuration: focusDuration,
//                 isCompleted: isCompleted,
//                 goal: goal)
//    }
}
