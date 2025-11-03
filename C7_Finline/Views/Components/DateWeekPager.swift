//
//  DateWeekPager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 03/11/25.
//

import SwiftUI

struct DateWeekPagerView: View {
    @Binding var selectedDate: Date
    @State private var weekIndex: Int = 0

    private let calendar = Calendar.current

    private func weekDates(for index: Int) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let baseWeekStart = calendar.date(
            byAdding: .day,
            value: 7 * index,
            to: today
        )!
        let startOfWeek = calendar.date(
            from: calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: baseWeekStart
            )
        )!

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let itemWidth = geo.size.width / 7
            let itemHeight: CGFloat = 70

            TabView(selection: $weekIndex) {
                ForEach(-10..<10, id: \.self) { index in
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
                    .frame(width: geo.size.width, height: itemHeight)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(height: 70)

    }
}

#Preview {
    DateWeekPagerView(selectedDate: .constant(Date()))
        .padding()
        .background(Color.gray.opacity(0.2))
}
