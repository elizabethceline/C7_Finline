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
    @State private var selectedDay: DayOfWeek = .monday
    @State private var hasChanges = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            DaySelectorView(selectedDay: $selectedDay)
                .padding(.top)

            TimeSlotListView(
                productiveHours: $productiveHoursState,
                selectedDay: selectedDay,
                onChange: { hasChanges = true }
            )

            Spacer()
        }
        .background(Color(uiColor: .systemGray6).ignoresSafeArea())
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
}

#Preview {
    EditProductiveHoursView(viewModel: ProfileViewModel())
}
