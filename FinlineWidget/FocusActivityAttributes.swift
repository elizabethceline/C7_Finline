//
//  FocusActivityAttributes.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 10/11/25.
//

import ActivityKit
import Foundation

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: TimeInterval
        var taskTitle: String
        var isResting: Bool
    }

    var goalName: String
}
