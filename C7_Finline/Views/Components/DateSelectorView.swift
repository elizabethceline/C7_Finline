//
//  DateSelectorView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct DateSelectorView: View {
    @Binding var selectedDate: Date

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { date in
                    DateItemView(
                        date: date,
                        isSelected: Calendar.current.isDate(
                            selectedDate,
                            inSameDayAs: date,
                        ),
                        hasUnfinishedTask: true
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.all, 4)
        }
    }
}

#Preview {
    DateSelectorView(selectedDate: .constant(Date()))
}
