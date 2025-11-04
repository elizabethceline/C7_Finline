//
//  TimeSlot.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Foundation

enum TimeSlot: String, CaseIterable, Codable {
    case earlyMorning = "Early morning"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    var hours: String {
        switch self {
        case .earlyMorning: return "Before 8am"
        case .morning: return "8AM-12PM"
        case .afternoon: return "12PM-5PM"
        case .evening: return "5PM-9PM"
        case .night: return "After 9PM"
        }
    }
}
