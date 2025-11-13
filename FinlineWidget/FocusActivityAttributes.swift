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
        var remainingTime: TimeInterval        // waktu sesi fokus
        var restRemainingTime: TimeInterval?   // waktu istirahat opsional
        var taskTitle: String
        var isResting: Bool
    }


    var goalName: String
    var totalDuration: TimeInterval 
}
