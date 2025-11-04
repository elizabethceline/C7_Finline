//
//  DateTimePickerView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 26/10/25.
//

import SwiftUI

struct DateTimePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var selection: Date
    let displayedComponents: DatePickerComponents

    var body: some View {
        NavigationStack {
            VStack {
                if displayedComponents == [.date] {
                    DatePicker(
                        "",
                        selection: $selection,
                        in: Date()...,
                        displayedComponents: displayedComponents
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal)
                } else {
                    DatePicker(
                        "",
                        selection: $selection,
                        displayedComponents: displayedComponents
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxHeight: 300)
                }

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DateTimePickerView(
        title: "Select Date",
        selection: .constant(Date()),
        displayedComponents: [.date]
    )
    .preferredColorScheme(.dark)
}
