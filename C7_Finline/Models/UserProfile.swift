//
//  UserProfile.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
class UserProfile {
    @Attribute(.unique) var id: String
    var username: String
    var points: Int
    var productiveHoursJSON: String
    var bestFocusTime: TimeInterval = 0
    var needsSync: Bool = false

    init(
        id: String,
        username: String,
        points: Int,
        productiveHours: [ProductiveHours],
        bestFocusTime: TimeInterval = 0,
        needsSync: Bool = false
    ) {
        self.id = id
        self.username = username
        self.points = points
        self.productiveHoursJSON = UserProfile.encode(productiveHours)
        self.bestFocusTime = bestFocusTime
        self.needsSync = needsSync
    }

    var productiveHours: [ProductiveHours] {
        get { UserProfile.decode(productiveHoursJSON) }
        set { self.productiveHoursJSON = UserProfile.encode(newValue) }
    }

    convenience init(record: CKRecord) {
        let id = record.recordID.recordName.replacingOccurrences(
            of: "UserProfile_",
            with: ""
        )
        let username = record["username"] as? String ?? ""
        let points = record["points"] as? Int ?? 0
        let productiveHours = UserProfile.decode(
            record["productive_hours"] as? String
        )
        let bestFocusTime = record["bestFocusTime"] as? Double ?? 0
        self.init(
            id: id,
            username: username,
            points: points,
            productiveHours: productiveHours,
            bestFocusTime: bestFocusTime
        )
    }

    func toRecord(_ record: CKRecord) -> CKRecord {
        record["username"] = username as CKRecordValue
        record["points"] = points as CKRecordValue
        record["productive_hours"] = productiveHoursJSON as CKRecordValue
        record["bestFocusTime"] = bestFocusTime as CKRecordValue
        return record
    }

    static func encode(_ hours: [ProductiveHours]) -> String {
        if let jsonData = try? JSONEncoder().encode(hours),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            return jsonString
        }
        return "[]"
    }

    static func decode(_ jsonString: String?) -> [ProductiveHours] {
        if let jsonString = jsonString,
           let jsonData = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(
               [ProductiveHours].self,
               from: jsonData
           )
        {
            return decoded
        }
        return DayOfWeek.allCases.map { ProductiveHours(day: $0) }
    }
}
