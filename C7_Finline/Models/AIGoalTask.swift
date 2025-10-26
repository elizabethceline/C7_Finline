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

    @Guide(description: """
        The scheduled working time (Date) within the user's productive hours and before the goal deadline.
        Each generated task should start at least 15 minutes after the previous task's end time 
        (previous workingTime + focusDuration). Ensure no overlapping between tasks.
        """)
    var workingTime: String

    @Guide(description: "Determine a reasonable focus duration in minutes that matches the task's difficulty — simpler tasks should take less time, while more complex ones should take longer. Maximun is 120 minute")
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
