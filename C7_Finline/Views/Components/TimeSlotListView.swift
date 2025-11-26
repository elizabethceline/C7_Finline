//
//  TimeSlotListView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 28/10/25.
//

import SwiftUI

struct TimeSlotListView: View {
    @Binding var productiveHours: [ProductiveHours]
    let selectedDay: DayOfWeek
    let onChange: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(TimeSlot.allCases, id: \.self) { slot in
                    let selected =
                        productiveHours
                        .first(where: { $0.day == selectedDay })?
                        .timeSlots.contains(slot) ?? false

                    Button {
                        toggleTimeSlot(day: selectedDay, slot: slot)
                        onChange()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(slot.rawValue.capitalized)
                                    .font(.headline)
                                    .foregroundColor(Color(uiColor: .label))
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
                                .primary.opacity(selected ? 1 : 0.6)
                            )
                            .font(.title2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            (colorScheme == .light
                                ? Color(.systemBackground)
                                : Color(.systemGray6))
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func toggleTimeSlot(day: DayOfWeek, slot: TimeSlot) {
        if let index = productiveHours.firstIndex(where: { $0.day == day }) {
            if productiveHours[index].timeSlots.contains(slot) {
                productiveHours[index].timeSlots.removeAll { $0 == slot }
            } else {
                productiveHours[index].timeSlots.append(slot)
            }
        }
    }
}

#Preview {
    TimeSlotListView(
        productiveHours: .constant([
            ProductiveHours(day: .monday, timeSlots: [.morning, .evening]),
            ProductiveHours(day: .tuesday, timeSlots: [.afternoon]),
        ]),
        selectedDay: .monday,
        onChange: {}
    )
    .background(Color(uiColor: .systemGray6))
}
