//
//  GoalCardView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 01/11/25.
//

import SwiftUI

struct GoalCardView: View {
    var goalName: String
    var goalDeadline: Date

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(goalName)
                        .font(.headline)
                        .fontWeight(.bold)
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.white.opacity(0.9))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due Date")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(DateFormatter.readableDate.string(from: goalDeadline)) | \(DateFormatter.readableTime.string(from: goalDeadline))")
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
    }
}

#Preview {
    GoalCardView(
        goalName: "Write my Thesis",
        goalDeadline: Calendar.current.date(from: DateComponents(
            year: 2025, month: 10, day: 14, hour: 9, minute: 41
        ))!
    )
}
