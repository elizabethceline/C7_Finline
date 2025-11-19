//
//  AIPlannedItem.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 18/11/25.
//

import Foundation
import FoundationModels

@Generable
struct AIPlannedItem: Codable, Equatable {
    @Guide(description: "A descriptive task title.")
    var name: String

    @Guide(description: "Focus duration in minutes. Must not exceed total available time.")
    var focusDuration: Int
}
