//
//  MainView+DateHandling.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 03/11/25.
//

import Foundation
import SwiftUI

extension MainView {

    func jumpToToday() {
        let today = calendar.startOfDay(for: Date())
        applyDateStateChange(targetDate: today)
    }

    func jumpToDate(_ date: Date) {
        let targetDate = calendar.startOfDay(for: date)
        applyDateStateChange(targetDate: targetDate)
    }

    private func applyDateStateChange(targetDate: Date) {
        isWeekChange = true

        withAnimation {
            updateWeekIndex(for: targetDate)
            selectedDate = targetDate
        }

        DispatchQueue.main.async {
            isWeekChange = false
        }
    }

    func updateSelectedDateFromWeekChange(oldValue: Int, newValue: Int) {
        guard !isWeekChange else { return }
        let delta = newValue - oldValue
        guard delta != 0 else { return }

        if let newDate = calendar.date(
            byAdding: .day,
            value: delta * 7,
            to: selectedDate
        ) {
            selectedDate = newDate
        }
    }

    private func updateWeekIndex(for date: Date) {
        let todayWeek = calendar.dateComponents(
            [.weekOfYear, .yearForWeekOfYear],
            from: calendar.startOfDay(for: Date())
        )
        let targetWeek = calendar.dateComponents(
            [.weekOfYear, .yearForWeekOfYear],
            from: date
        )

        if let diff = calendar.dateComponents(
            [.weekOfYear],
            from: todayWeek,
            to: targetWeek
        ).weekOfYear {
            currentWeekIndex = diff
        }
    }
}
