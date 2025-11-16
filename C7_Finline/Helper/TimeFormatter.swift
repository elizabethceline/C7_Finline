//
//  TimeFormatter.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 10/11/25.
//

import Foundation

enum TimeFormatter {
    static func format(seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    static func shortFormat(seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        return "\(minutes)m"
    }
}
