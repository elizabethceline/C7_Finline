//
//  GoalCardView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 01/11/25.
//

import SwiftUI
import SwiftData
import FoundationModels

struct GoalCardView: View {
    @ObservedObject var goalVM: GoalViewModel
    @Environment(\.modelContext) private var modelContext

    var goal: Goal

    @State private var isShowingEditModal = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(goal.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    Button {
                        isShowingEditModal = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.white.opacity(0.9))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due Date")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(DateFormatter.readableDate.string(from: goal.due)) | \(DateFormatter.readableTime.string(from: goal.due))")
                            .font(.subheadline)
                            .bold()
                            .underline()
                            .foregroundColor(.white)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(red: 0.54, green: 0.67, blue: 0.98))
        .cornerRadius(15)
        .shadow(radius: 2)
        .sheet(isPresented: $isShowingEditModal) {
            EditGoalView(goalVM: goalVM, goal: goal)
                .presentationDetents([.medium]) 
        }
    }
}
