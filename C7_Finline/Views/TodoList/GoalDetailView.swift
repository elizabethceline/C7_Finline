//#
//  GoalDetailView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 01/11/25.
//

import SwiftUI

struct DetailGoalView: View {
    let goal: Goal
    let goalManager: GoalManager

    var body: some View {
        VStack(spacing: 16) {
            GoalCardView(goalName: goal.name, goalDeadline: goal.due)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Goal Detail")
    }
}

