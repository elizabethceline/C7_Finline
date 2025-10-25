//
//  Goal.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
class Goal {
    @Attribute(.unique) var id: String
    var name: String
    var due: Date
    var goalDescription: String?
    var needsSync: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
    var tasks: [GoalTask] = []

    init(
        id: String,
        name: String,
        due: Date,
        goalDescription: String?,
        needsSync: Bool = false
    ) {
        self.id = id
        self.name = name
        self.due = due
        self.goalDescription = goalDescription
        self.needsSync = needsSync
    }

    convenience init(record: CKRecord) {
        self.init(
            id: record.recordID.recordName,
            name: record["name"] as? String ?? "",
            due: record["due"] as? Date ?? Date(),
            goalDescription: record["description"] as? String
        )
    }
}
