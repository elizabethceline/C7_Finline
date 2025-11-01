//#
//  GoalDetailView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 01/11/25.
//

import SwiftUI
import FoundationModels

struct DetailGoalView: View {
    let goal: Goal
    @ObservedObject var goalVM: GoalViewModel

    var body: some View {
        VStack(spacing: 16) {
            GoalCardView(goalVM: goalVM, goal: goal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Goal Detail")
    }
}

#Preview {
    let sampleGoal = Goal(
        id: UUID().uuidString,
        name: "Finish Thesis Chapter 3",
        due: Calendar.current.date(
            from: DateComponents(year: 2025, month: 11, day: 10, hour: 17, minute: 30)
        )!,
        goalDescription: "Complete the methodology section and review references."
    )

    let goalVM = GoalViewModel()

    return NavigationStack {
        DetailGoalView(goal: sampleGoal, goalVM: goalVM)
    }
}

