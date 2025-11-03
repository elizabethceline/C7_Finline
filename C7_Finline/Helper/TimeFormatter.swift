//
//  TimeFormatter.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 03/11/25.
//
import Foundation

enum TimeFormatter {
    static func format(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
