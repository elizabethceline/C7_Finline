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
                        .font(.title)
                        .fontWeight(.bold)
                    Button {
                        isShowingEditModal = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.title2)
                            .foregroundStyle(Color.black)
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
                            .bold()
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(
            Color(red: 203/255, green: 233/255, blue: 244/255)
        )
        .sheet(isPresented: $isShowingEditModal) {
            EditGoalView(goalVM: goalVM, goal: goal)
                .presentationDetents([.medium])
        }
    }
}
