//
//  CreateGoalView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 26/10/25.
//

import SwiftUI

struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var mainVM: MainViewModel

    @State private var goalName: String = ""
    @State private var goalDeadline: Date = Date()
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
                }

                Section {
                    Button {
                        isShowingDatePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(goalDeadline.formatted(date: .long, time: .omitted))
                                    .font(.body)
                                    .foregroundColor(Color(.label))
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .foregroundColor(Color(.label))
                        }
                        .foregroundStyle(.black)
                    }

                    Button {
                        isShowingTimePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(goalDeadline.formatted(date: .omitted, time: .shortened))
                                    .font(.body)
                                    .foregroundColor(Color(.label))
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(.label))
                        }
                        .foregroundStyle(.black)
                    }
                } header: {
                    Text("Deadline")
                        .font(.headline)
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
                    NavigationLink(destination: CreateTaskView(goalName: goalName, goalDeadline: goalDeadline,dismissParent: dismiss, mainVM: mainVM)) {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(goalName.isEmpty)

                }
            }
            .sheet(isPresented: $isShowingDatePicker) {
                DateTimePickerView(
                    title: "Select Date",
                    selection: $goalDeadline,
                    displayedComponents: [.date]
                )
            }
            .sheet(isPresented: $isShowingTimePicker) {
                DateTimePickerView(
                    title: "Select Time",
                    selection: $goalDeadline,
                    displayedComponents: [.hourAndMinute]
                )            }
        }
    }
}

#Preview {
    CreateGoalView(mainVM: MainViewModel())
        .preferredColorScheme(.dark)
}
