//
//  CreateGoalView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 26/10/25.
//

import SwiftUI

struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var goalName: String = ""
    @State private var deadlineDate: Date = Date()
    @State private var isShowingDatePicker: Bool = false
    @State private var isShowingTimePicker: Bool = false
    

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal Name", text: $goalName)
                        .font(.body)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    } header: {
                        Text("Goal")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        isShowingDatePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(deadlineDate.formatted(date: .long, time: .omitted))
                                    .font(.body)
                            } icon: {
                                Image(systemName: "calendar")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        isShowingTimePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(deadlineDate.formatted(date: .omitted, time: .shortened))
                                    .font(.body)
                            } icon: {
                                Image(systemName: "clock")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Deadline")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Create Goal")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $isShowingDatePicker) {
                DateTimePickerView(
                    title: "Select Date",
                    selection: $deadlineDate,
                    displayedComponents: [.date]
                )
            }
            .sheet(isPresented: $isShowingTimePicker) {
                DateTimePickerView(
                    title: "Select Time",
                    selection: $deadlineDate,
                    displayedComponents: [.hourAndMinute]
                )
            }
        }
    }
}

#Preview {
    CreateGoalView()
        .preferredColorScheme(.dark)
}
