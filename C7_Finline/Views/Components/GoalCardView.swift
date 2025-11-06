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
                        .font(.title2)
                        .fontWeight(.semibold)
                    Button {
                        isShowingEditModal = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.title2)
                            .foregroundStyle(Color(.label))
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due Date")
                            .font(.subheadline)
                        
                        Text("\(DateFormatter.readableDate.string(from: goal.due)) | \(DateFormatter.readableTime.string(from: goal.due))")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                    }
                    
                }
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))

        .sheet(isPresented: $isShowingEditModal) {
            EditGoalView(goalVM: goalVM, goal: goal)
                .presentationDetents([.medium])
        }
    }
}
