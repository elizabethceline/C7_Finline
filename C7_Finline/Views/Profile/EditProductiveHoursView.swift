//
//  EditProductiveHoursView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 28/10/25.
//

import SwiftUI

struct EditProductiveHoursView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var productiveHoursState: [ProductiveHours] = []
    @State private var selectedTimeSlots: Set<TimeSlot> = []
    @State private var includeWeekend: Bool = false
    @State private var hasChanges = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 16) {
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
                                    selected
                                        ? .primary : .primary.opacity(0.6)
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
                        if !selectedTimeSlots.isEmpty {
                            includeWeekend.toggle()
                            hasChanges = true
                        }
                    } label: {
                        HStack {
                            Text("Are you productive at weekend?")
                                .font(.headline)
                                .foregroundColor(
                                    selectedTimeSlots.isEmpty
                                        ? Color(uiColor: .secondaryLabel)
                                        : Color(uiColor: .label)
                                )
                            Spacer()
                            Image(
                                systemName: includeWeekend
                                    ? "checkmark.square.fill" : "square"
                            )
                            .foregroundColor(
                                selectedTimeSlots.isEmpty
                                    ? .primary.opacity(0.3)
                                    : (includeWeekend
                                        ? Color.primary
                                        : .primary.opacity(0.6))
                            )
                            .font(.title2)
                        }
                        .padding(.trailing)
                        .padding(.leading, 8)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedTimeSlots.isEmpty)
                }
                .padding(.top, 1)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .background(
            (colorScheme == .light
                ? Color(.systemGray6)
                : Color(.systemBackground)).ignoresSafeArea()
        )
        .navigationTitle("Activity Time")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProductiveHours()
                    viewModel.saveUserProfile(
                        username: viewModel.username,
                        productiveHours: productiveHoursState,
                        points: viewModel.points
                    )
                    hasChanges = false
                    dismiss()
                }
                .disabled(!hasChanges)
            }
        }
        .onAppear {
            productiveHoursState = viewModel.productiveHours
            loadCurrentSelection()
        }
        .onChange(of: selectedTimeSlots) { oldValue, newValue in
            hasChanges = true
            // Uncheck weekend if all time slots are deselected
            if newValue.isEmpty {
                includeWeekend = false
            }
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
        // Load time slots from Monday (weekday representative)
        if let monday = productiveHoursState.first(where: { $0.day == .monday })
        {
            selectedTimeSlots = Set(monday.timeSlots)
        }

        // Check if weekend has same selections
        if let saturday = productiveHoursState.first(where: {
            $0.day == .saturday
        }),
            let sunday = productiveHoursState.first(where: { $0.day == .sunday }
            ),
            !saturday.timeSlots.isEmpty || !sunday.timeSlots.isEmpty
        {
            includeWeekend = true
        }
    }

    private func saveProductiveHours() {
        let timeSlotsArray = Array(selectedTimeSlots)

        // Apply to weekdays (Monday-Friday)
        let weekdays: [DayOfWeek] = [
            .monday, .tuesday, .wednesday, .thursday, .friday,
        ]
        for day in weekdays {
            if let index = productiveHoursState.firstIndex(where: {
                $0.day == day
            }) {
                productiveHoursState[index].timeSlots = timeSlotsArray
            }
        }

        // Apply to weekends (Saturday-Sunday)
        let weekendDays: [DayOfWeek] = [.saturday, .sunday]
        for day in weekendDays {
            if let index = productiveHoursState.firstIndex(where: {
                $0.day == day
            }) {
                productiveHoursState[index].timeSlots =
                    includeWeekend ? timeSlotsArray : []
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProductiveHoursView(viewModel: ProfileViewModel())
    }
}
