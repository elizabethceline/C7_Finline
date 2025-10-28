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
    
    private var existingTask: AIGoalTask?
    
    init(taskVM: TaskViewModel, taskDeadline: Date = Date(), existingTask: AIGoalTask? = nil) {
        self.taskVM = taskVM
        self.existingTask = existingTask
        
        if let existingTask = existingTask {
            _taskName = State(initialValue: existingTask.name)
            let formatter = ISO8601DateFormatter()
            let parsedDate = formatter.date(from: existingTask.workingTime) ?? Date()
            _taskDeadline = State(initialValue: parsedDate)
            _focusDuration = State(initialValue: existingTask.focusDuration)
        } else {
            _taskDeadline = State(initialValue: taskDeadline)
        }
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
            .navigationTitle(existingTask == nil ? "Create Task" : "Edit Task")
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
                        let dateFormatter = ISO8601DateFormatter()
                        let formattedDate = dateFormatter.string(from: taskDeadline)
                        
                        if let existingTask = existingTask {
                            taskVM.updateTask(
                                existingTask,
                                name: taskName,
                                workingTime: formattedDate,
                                focusDuration: focusDuration
                            )
                        } else {
                            taskVM.createTaskManually(
                                name: taskName,
                                workingTime: taskDeadline,
                                focusDuration: focusDuration
                            )
                        }
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
        CreateTaskManuallyView(taskVM: dummyTaskVM, taskDeadline: Date())
    }
    .preferredColorScheme(.light)
}
