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
        VStack(spacing: 8) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Find Your Best Time to Work")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)

                Text(
                    "Our AI analyzes your activity and shows you the time when you are most focused."
                )
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding()

            HStack {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    Button {
                        selectedDay = day
                    } label: {
                        Text(day.shortLabel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedDay == day ? Color.blue : Color.white
                            )
                            .foregroundColor(
                                selectedDay == day ? .white : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal)

            // Time slot
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(TimeSlot.allCases, id: \.self) { slot in
                        let selected =
                            productiveHours.first(where: {
                                $0.day == selectedDay
                            })?
                            .timeSlots.contains(slot) ?? false

                        Button {
                            toggleTimeSlot(day: selectedDay, slot: slot)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(slot.rawValue.capitalized)
                                        .font(.headline)
                                    Text(slot.hours)
                                        .font(.caption)
                                }
                                Spacer()
                                Image(
                                    systemName: selected
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundColor(
                                    .blue.opacity(selected ? 1 : 0.6)
                                )
                                .font(.title2)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Start button
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
    SetProductiveHoursView(
        productiveHours: .constant(
            DayOfWeek.allCases.map { ProductiveHours(day: $0) }
        ),
        onComplete: {}
    )
}
