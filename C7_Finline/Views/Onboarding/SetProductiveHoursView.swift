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
        ZStack {
            // Background
            OnboardingBackground()

            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What’s your best productivity time?")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(uiColor: .label))

                    Text(
                        "Finley will analyze your activity and shows you the time when you are most focused."
                    )
                    .font(.body)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .padding()

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
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 50))
                    }

                    Button {
                        onComplete()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
            }
        }
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
