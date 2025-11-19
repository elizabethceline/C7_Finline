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
    @State private var focusDuration: Int = 1
    
    @State private var isShowingDatePicker: Bool = false
    @State private var isShowingTimePicker: Bool = false
    @State private var isShowingDurationPicker = false
    @State private var isShowingDeleteAlert = false
    
    @State private var durationHours = 0
    @State private var durationMinutes = 1
    @State private var durationSeconds = 0
    
    
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
            
            let hours = existingTask.focusDuration / 60
            let minutes = existingTask.focusDuration % 60
            _durationHours = State(initialValue: hours)
            _durationMinutes = State(initialValue: minutes)
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
                    Button {
                        isShowingDurationPicker = true
                    } label: {
                        HStack {
                            Label {
                                if durationHours == 0 {
                                    Text("\(durationMinutes) mins")
                                        .font(.body)
                                        .foregroundColor(Color(.label))
                                } else if durationMinutes == 0 {
                                    Text("\(durationHours) hours")
                                        .font(.body)
                                        .foregroundColor(Color(.label))
                                } else {
                                    Text("\(durationHours) hours \(durationMinutes) mins")
                                        .font(.body)
                                        .foregroundColor(Color(.label))
                                }
                            } icon: {
                                Image(systemName: "timer")
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(.label))
                        }
                        .foregroundStyle(.black)
                    }
                    .sheet(isPresented: $isShowingDurationPicker) {
                        TimerPickerSheetView(
                            hours: $durationHours,
                            minutes: $durationMinutes
                        ) { totalMinutes in
                            focusDuration = totalMinutes
                        }
                    }
                    
                } header: {
                    Text("Schedule")
                        .font(.headline)
                }
                
                
            }
            .safeAreaInset(edge: .bottom) {
                //start focus
                
                if existingTask != nil {
                    Button(role: .destructive) {
                        isShowingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Task")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(existingTask == nil ? "Create Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .alert("Delete Task?", isPresented: $isShowingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let taskToDelete = existingTask {
                        taskVM.deleteTask(taskToDelete)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
            
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
