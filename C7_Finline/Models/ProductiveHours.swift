//
//  ProductiveHours.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Foundation

struct ProductiveHours: Codable {
    var day: DayOfWeek
    var timeSlots: [TimeSlot]

    init(day: DayOfWeek, timeSlots: [TimeSlot] = []) {
        self.day = day
        self.timeSlots = timeSlots
    }
}
