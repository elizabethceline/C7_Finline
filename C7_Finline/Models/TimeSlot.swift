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
        case .earlyMorning: return "3AM - 8AM"
        case .morning: return "8AM - 12PM"
        case .afternoon: return "12PM - 5PM"
        case .evening: return "5PM - 9PM"
        case .night: return "9PM - 12AM"
        }
    }
    
    var order: Int {
            switch self {
            case .earlyMorning: return 0
            case .morning: return 1
            case .afternoon: return 2
            case .evening: return 3
            case .night: return 4
            }
        }
}
