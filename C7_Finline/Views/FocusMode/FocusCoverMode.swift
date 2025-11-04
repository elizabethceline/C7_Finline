//
//  FocusCoverMode.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 04/11/25.
//

import Foundation
import SwiftData

enum FocusCoverMode: Identifiable {
    case detail(GoalTask)
    case focus
        
    var id: String {
        switch self {
        case .detail(let task): return "detail-\(task.id)"
        case .focus: return "focus"
        }
    }
}
