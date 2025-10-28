//
//  GoalTask.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
class GoalTask {
    @Attribute(.unique) var id: String
    var name: String
    var workingTime: Date
    var focusDuration: Int
    var isCompleted: Bool
    var needsSync: Bool = false
    var goal: Goal?

    init(
        id: String,
        name: String,
        workingTime: Date,
        focusDuration: Int,
        isCompleted: Bool,
        goal: Goal?,
        needsSync: Bool = false
    ) {
        self.id = id
        self.name = name
        self.workingTime = workingTime
        self.focusDuration = focusDuration
        self.isCompleted = isCompleted
        self.goal = goal
        self.needsSync = needsSync
    }

    convenience init(record: CKRecord, goal: Goal?) {
        self.init(
            id: record.recordID.recordName,
            name: record["name"] as? String ?? "",
            workingTime: record["working_time"] as? Date ?? Date(),
            focusDuration: record["focus_duration"] as? Int ?? 0,
            isCompleted: record["is_completed"] as? Int == 1,
            goal: goal
        )
    }
}
