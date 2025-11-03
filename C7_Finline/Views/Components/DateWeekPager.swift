//
//  DateWeekPager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 03/11/25.
//

import SwiftUI

struct DateWeekPagerView: View {
    @Binding var selectedDate: Date
    @Binding var weekIndex: Int
    @Binding var isWeekChange: Bool

    @State private var weekRange: ClosedRange<Int> = -50...50
    private let calendar = Calendar.current

    // get dates for the week at given index
    private func weekDates(for index: Int) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let baseDate = calendar.date(
            byAdding: .day,
            value: index * 7,
            to: today
        )!
        let startOfWeek = calendar.date(
            from: calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: baseDate
            )
        )!

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    // synchronize pager to selected date
    private func syncPagerToSelectedDate() {
        let currentWeek = calendar.dateComponents(
            [.weekOfYear, .yearForWeekOfYear],
            from: calendar.startOfDay(for: Date())
        )
        let targetWeek = calendar.dateComponents(
            [.weekOfYear, .yearForWeekOfYear],
            from: selectedDate
        )

        if let diff = calendar.dateComponents(
            [.weekOfYear],
            from: currentWeek,
            to: targetWeek
        ).weekOfYear {
            // expand range
            if diff < weekRange.lowerBound {
                weekRange = (diff - 20)...weekRange.upperBound
            } else if diff > weekRange.upperBound {
                weekRange = weekRange.lowerBound...(diff + 20)
            }

            isWeekChange = true
            withAnimation {
                weekIndex = diff
            }
            DispatchQueue.main.async {
                isWeekChange = false
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let itemWidth = geo.size.width / 7
            let itemHeight: CGFloat = 64

            TabView(selection: $weekIndex) {
                ForEach(weekRange, id: \.self) { index in
                    let dates = weekDates(for: index)

                    HStack(spacing: 0) {
                        ForEach(dates, id: \.self) { date in
                            DateItemView(
                                date: date,
                                isSelected: calendar.isDate(
                                    selectedDate,
                                    inSameDayAs: date
                                )
                            ) {
                                selectedDate = date
                            }
                            .frame(width: itemWidth, height: itemHeight)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(height: 64)
        .onChange(of: selectedDate) { _, _ in
            syncPagerToSelectedDate()
        }
    }
}

#Preview {
    DateWeekPagerView(
        selectedDate: .constant(Date()),
        weekIndex: .constant(0),
        isWeekChange: .constant(false)
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
