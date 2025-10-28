//
//  CreateTaskManually.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 28/10/25.
//

import SwiftUI

struct CreateTaskManuallyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskVM: TaskViewModel
    
    @State private var taskName: String = ""
    @State private var taskDeadline: Date
    @State private var focusDuration: Int = 60
    
    @State private var isShowingDatePicker: Bool = false
    @State private var isShowingTimePicker: Bool = false
    
    init(taskVM: TaskViewModel, taskDeadline: Date = Date()) {
        self.taskVM = taskVM
        _taskDeadline = State(initialValue: taskDeadline)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Name", text: $taskName)
                        .font(.body)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                } header: {
                    Text("Task")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        isShowingDatePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(taskDeadline.formatted(date: .long, time: .omitted))
                                    .font(.body)
                            } icon: {
                                Image(systemName: "calendar")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.black)
                    }

                    Button {
                        isShowingTimePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(taskDeadline.formatted(date: .omitted, time: .shortened))
                                    .font(.body)
                            } icon: {
                                Image(systemName: "clock")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.black)
                    }
                    
                    Stepper(value: $focusDuration, in: 1...180, step: 1) {
                        HStack {
                            Text("Focus Duration")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(focusDuration) mins")
                                .font(.body)
                        }
                    }
                } header: {
                    Text("Schedule")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Create Task")
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
                        taskVM.createTaskManually(
                            name: taskName,
                            workingTime: taskDeadline,
                            focusDuration: focusDuration
                        )
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(taskName.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingDatePicker) {
                DateTimePickerView(
                    title: "Select Date",
                    selection: $taskDeadline,
                    displayedComponents: [.date]
                )
            }
            .sheet(isPresented: $isShowingTimePicker) {
                DateTimePickerView(
                    title: "Select Time",
                    selection: $taskDeadline,
                    displayedComponents: [.hourAndMinute]
                )
            }
        }
    }
}

#Preview {
    let dummyTaskVM = TaskViewModel()
    
    return NavigationStack {
        CreateTaskManuallyView(
            taskVM: dummyTaskVM,
            taskDeadline: Date()
        )
    }
    .preferredColorScheme(.light)
}

