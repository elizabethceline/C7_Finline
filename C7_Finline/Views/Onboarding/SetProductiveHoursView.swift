//
//  SetProductiveHoursView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftUI

struct SetProductiveHoursView: View {
    @Binding var productiveHours: [ProductiveHours]
    let onComplete: () -> Void
    @State private var selectedDay: DayOfWeek = .monday

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Find Your Best Time to Work")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)

                Text("Our AI analyzes your activity and shows you the time when you are most focused.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Day selector
            DaySelectorView(selectedDay: $selectedDay)

            // Time slots
            TimeSlotListView(
                productiveHours: $productiveHours,
                selectedDay: selectedDay,
                onChange: {}
            )

            // Buttons
            VStack(spacing: 16) {
                Button {
                    onComplete()
                } label: {
                    Text("Start Productivity")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                }

                Button {
                    onComplete()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    SetProductiveHoursView(
        productiveHours: .constant(
            DayOfWeek.allCases.map { ProductiveHours(day: $0) }
        ),
        onComplete: {}
    )
}
