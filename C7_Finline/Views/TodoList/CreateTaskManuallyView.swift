//
//  CreateTaskManually.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 28/10/25.
//

import SwiftUI
import SwiftData

struct CreateTaskManuallyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskVM: TaskViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var taskName: String = ""
    @State private var taskDeadline: Date
    @State private var focusDuration: Int = 60
    
    @State private var isShowingDatePicker: Bool = false
    @State private var isShowingTimePicker: Bool = false
    
    private var existingTask: AIGoalTask?
    private var goalId: String?
    var onTaskCreated: (() -> Void)?
    
    init(
        taskVM: TaskViewModel,
        taskDeadline: Date = Date(),
        existingTask: AIGoalTask? = nil,
        goalId: String? = nil,  
        onTaskCreated: (() -> Void)? = nil
    ) {
        self.taskVM = taskVM
        self.existingTask = existingTask
        self.goalId = goalId
        self.onTaskCreated = onTaskCreated
        
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
                }

                Section {
                    Button {
                        isShowingDatePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(taskDeadline.formatted(date: .long, time: .omitted))
                                    .font(.body)
                                    .foregroundColor(Color(.label))
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(.label))
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
                                    .foregroundColor(Color(.label))
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                            .foregroundColor(Color(.label))                        }
                        .foregroundStyle(.black)
                    }
                    
                    Stepper(value: $focusDuration, in: 1...180, step: 1) {
                        HStack {
                            Text("Focus Duration")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(focusDuration) mins")
                                .font(.body)
                                .foregroundColor(Color(.label))
                        }
                    }
                } header: {
                    Text("Schedule")
                        .font(.headline)
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
                        } else if let goalId = goalId {
                            Task {
                                await taskVM.createTaskForGoal(
                                    goalId: goalId,
                                    name: taskName,
                                    workingTime: taskDeadline,
                                    focusDuration: focusDuration,
                                    modelContext: modelContext
                                )
                                onTaskCreated?()
                            }
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
