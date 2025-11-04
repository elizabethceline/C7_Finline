//
//  DateHeaderView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 03/11/25.
//

import SwiftUI

struct DateHeaderView: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekIndex: Int
    @Binding var showDatePicker: Bool
    @Binding var isWeekChange: Bool

    let jumpToDate: (Date) -> Void
    let unfinishedTasks: [GoalTask]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    showDatePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.title)
                            .foregroundColor(.primary)

                        Text(
                            selectedDate.formatted(.dateTime.month(.wide)) + " "
                                + selectedDate.formatted(.dateTime.year())
                        )
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {

                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.title)
                        .foregroundColor(Color(.systemGray))
                }
            }
            .padding(.trailing, 4)

            DateWeekPagerView(
                selectedDate: $selectedDate,
                weekIndex: $currentWeekIndex,
                isWeekChange: $isWeekChange,
                unfinishedTasks: unfinishedTasks
            )

            Divider()
        }
        .padding(.horizontal)
    }
}

#Preview {
    DateHeaderView(
        selectedDate: .constant(Date()),
        currentWeekIndex: .constant(0),
        showDatePicker: .constant(false),
        isWeekChange: .constant(false),
        jumpToDate: { _ in },
        unfinishedTasks: []
    )
    .padding()
    .background(Color(.systemGray6))
}
