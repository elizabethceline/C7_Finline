//
//  FocusSessionResult.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 03/11/25.
//


import SwiftData
import Foundation

@Model
final class FocusSessionResult {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var duration: TimeInterval
    var caughtFish: [Fish]
    var task: GoalTask?

    var totalPoints: Int {
        caughtFish.reduce(0) { $0 + $1.points }
    }

    init(
        caughtFish: [Fish],
        duration: TimeInterval,
        task: GoalTask? = nil,
        date: Date = .now
    ) {
        self.caughtFish = caughtFish
        self.duration = duration
        self.date = date
        self.task = task
    }
}
