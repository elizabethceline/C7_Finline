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

    @State private var selectedTimeSlots: Set<TimeSlot> = []
    @State private var includeWeekend: Bool = false

    var body: some View {
        ZStack {
            // Background
            OnboardingBackground()

            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What’s your best productivity time?")
                        .font(.title)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(uiColor: .label))

                    Text(
                        "The app will schedule the tasks you need to do based on your best productivity time."
                    )
                    .font(.body)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .padding()

                // Time slots
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(TimeSlot.allCases, id: \.self) { slot in
                            let selected = selectedTimeSlots.contains(slot)

                            Button {
                                toggleTimeSlot(slot)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(slot.rawValue)
                                            .font(.headline)
                                            .foregroundColor(
                                                Color(uiColor: .label)
                                            )
                                        Text(slot.hours)
                                            .font(.caption)
                                            .foregroundColor(
                                                Color(uiColor: .secondaryLabel)
                                            )
                                    }
                                    Spacer()
                                    Image(
                                        systemName: selected
                                            ? "checkmark.square.fill" : "square"
                                    )
                                    .foregroundColor(
                                        selected
                                            ? .primary : .primary.opacity(0.6)
                                    )
                                    .font(.title2)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            selected
                                                ? Color.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Weekend toggle
                        Button {
                            includeWeekend.toggle()
                        } label: {
                            HStack {
                                Text("Are you productive at weekend?")
                                    .font(.headline)
                                    .foregroundColor(Color(uiColor: .label))
                                Spacer()
                                Image(
                                    systemName: includeWeekend
                                        ? "checkmark.square.fill" : "square"
                                )
                                .foregroundColor(
                                    includeWeekend
                                        ? Color.primary : .primary.opacity(0.6)
                                )
                                .font(.title2)
                            }
                            .padding(.trailing)
                            .padding(.leading, 8)
                            .padding(.top, 12)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 1)
                    .padding(.horizontal)
                }

                // Buttons
                VStack(spacing: 16) {
                    Button {
                        saveProductiveHours()
                        onComplete()
                    } label: {
                        Text("Done")
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
        .onAppear {
            loadCurrentSelection()
        }
    }

    private func toggleTimeSlot(_ slot: TimeSlot) {
        if selectedTimeSlots.contains(slot) {
            selectedTimeSlots.remove(slot)
        } else {
            selectedTimeSlots.insert(slot)
        }
    }

    private func loadCurrentSelection() {
        if let monday = productiveHours.first(where: { $0.day == .monday }) {
            selectedTimeSlots = Set(monday.timeSlots)
        }

        // Check if weekend has same selections
        if let saturday = productiveHours.first(where: { $0.day == .saturday }),
            let sunday = productiveHours.first(where: { $0.day == .sunday }),
            !saturday.timeSlots.isEmpty || !sunday.timeSlots.isEmpty
        {
            includeWeekend = true
        }
    }

    private func saveProductiveHours() {
        let timeSlotsArray = Array(selectedTimeSlots)

        let weekdays: [DayOfWeek] = [
            .monday, .tuesday, .wednesday, .thursday, .friday,
        ]
        for day in weekdays {
            if let index = productiveHours.firstIndex(where: { $0.day == day })
            {
                productiveHours[index].timeSlots = timeSlotsArray
            }
        }

        let weekendDays: [DayOfWeek] = [.saturday, .sunday]
        for day in weekendDays {
            if let index = productiveHours.firstIndex(where: { $0.day == day })
            {
                productiveHours[index].timeSlots =
                    includeWeekend ? timeSlotsArray : []
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
