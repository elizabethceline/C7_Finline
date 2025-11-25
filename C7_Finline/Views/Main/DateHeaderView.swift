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
    @Binding var taskFilter: TaskFilter

    let jumpToDate: (Date) -> Void
    let unfinishedTasks: [GoalTask]

    @Environment(\.colorScheme) var colorScheme

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
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Spacer()

                Menu {
                    Picker("Filter", selection: $taskFilter) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.subheadline)
                            .foregroundColor(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.8)
                                    : Color(.darkGray)
                            )
                            .fontWeight(.bold)
                        Text("\(taskFilter.rawValue)")
                            .font(.caption)
                            .foregroundColor(Color(.systemGray))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(width: 110, alignment: .leading)
                    .background(
                        (colorScheme == .light
                            ? Color.gray.opacity(0.1) : Color(.systemGray6))
                            .ignoresSafeArea()
                    )
                    .cornerRadius(50)
                }
                .menuStyle(.button)
                .fixedSize()
            }

            DateWeekPagerView(
                selectedDate: $selectedDate,
                weekIndex: $currentWeekIndex,
                isWeekChange: $isWeekChange,
                unfinishedTasks: unfinishedTasks
            )

            Divider()
                .background(
                    colorScheme == .light ? Color(.systemGray6) : Color(.gray)
                )
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
        taskFilter: .constant(.unfinished),
        jumpToDate: { _ in },
        unfinishedTasks: []
    )
    .padding()
    .background(Color(.systemBackground))
}
