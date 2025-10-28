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
    @State private var hasChanges = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach($productiveHoursState, id: \.day) { $dayHours in
                Section(dayHours.day.rawValue) {
                    ForEach(TimeSlot.allCases, id: \.self) { slot in
                        Button {
                            toggleTimeSlot(day: dayHours.day, slot: slot)
                        } label: {
                            HStack {
                                Text("\(slot.rawValue), \(slot.hours)")
                                    .foregroundColor(.primary)
                                Spacer()
                                if dayHours.timeSlots.contains(slot) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Activity Time")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
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
        }
    }

    private func toggleTimeSlot(day: DayOfWeek, slot: TimeSlot) {
        if let index = productiveHoursState.firstIndex(where: { $0.day == day })
        {
            if productiveHoursState[index].timeSlots.contains(slot) {
                productiveHoursState[index].timeSlots.removeAll { $0 == slot }
            } else {
                productiveHoursState[index].timeSlots.append(slot)
            }
            if !hasChanges { hasChanges = true }
        }
    }
}

#Preview {
    NavigationStack {
        EditProductiveHoursView(
            viewModel: ProfileViewModel()
        )
    }
}
