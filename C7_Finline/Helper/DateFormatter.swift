//
//  DateFormatter.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 26/10/25.
//

import Foundation

extension DateFormatter {
    static let readableDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_EN")
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    static let readableTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_EN")
        f.dateFormat = "HH.mm"
        return f
    }()
}


extension ISO8601DateFormatter {
    static func parse(_ string: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = f1.date(from: string) {
            return date
        }

        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: string)
    }
}

