//
//  ContentCardView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct ContentCardView: View {
    @Binding var selectedDate: Date
    let filteredTasks: [GoalTask]
    let goals: [Goal]
    
    private var goalsForSelectedDate: [Goal] {
        goals.filter { goal in
            goal.tasks.contains { task in
                Calendar.current.isDate(task.workingTime, inSameDayAs: selectedDate)
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemGray6))
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                DateSelectorView(selectedDate: $selectedDate)
                    .padding(.top, 32)

                Divider()
                    .padding()

                if filteredTasks.isEmpty {
                    EmptyStateView()
                        .padding(.top, 24)
                } else {
                    TaskListView(
                        tasks: filteredTasks,
                        goals: goalsForSelectedDate,
                        selectedDate: selectedDate
                    )
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
        }
    }
}

#Preview {
    ContentCardView(
        selectedDate: .constant(Date()),
        filteredTasks: [],
        goals: []
    )
}
