//
//  DetailTask.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 30/10/25.
//

import SwiftUI
import SwiftData

struct DetailTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var taskName: String = ""
    @State private var taskDate: Date = Date()
    @State private var focusDuration: Int = 60
    @State private var isCompleted: Bool = false
    
    @State private var isShowingDatePicker: Bool = false
    @State private var isShowingTimePicker: Bool = false
    @State private var isDeepFocusOn: Bool = false
    @State private var isNudgeMeOn: Bool = false
    
    @ObservedObject var taskVM: TaskViewModel
    
    let task: GoalTask
    let taskManager: TaskManager
    
    init(task: GoalTask, taskManager: TaskManager, viewModel: TaskViewModel) {
        self.task = task
        self.taskManager = taskManager
        self.taskVM = viewModel
        
        _taskName = State(initialValue: task.name)
        _taskDate = State(initialValue: task.workingTime)
        _focusDuration = State(initialValue: task.focusDuration)
        _isCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Name") {
                    TextField("Task Name", text: $taskName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Section("Schedule") {
                    Button {
                        isShowingDatePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(taskDate.formatted(date: .long, time: .omitted))
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
                                Text(taskDate.formatted(date: .omitted, time: .shortened))
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
                }
                Section {
                    HStack(spacing: 16) {
                        ToggleCardView(icon: "moon.fill", title: "Deep Focus", isOn: $isDeepFocusOn)
                        ToggleCardView(icon: "bell.fill", title: "Nudge Me", isOn: $isNudgeMeOn)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
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
                        saveChanges()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(taskName.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                }) {
                    Text("Start Focus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .padding([.horizontal, .bottom])
                }
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $isShowingDatePicker) {
                DateTimePickerView(
                    title: "Select Date",
                    selection: $taskDate,
                    displayedComponents: [.date]
                )
            }
            .sheet(isPresented: $isShowingTimePicker) {
                DateTimePickerView(
                    title: "Select Time",
                    selection: $taskDate,
                    displayedComponents: [.hourAndMinute]
                )
            }
            .presentationDetents([.large])
        }
    }
    
    private func saveChanges() {
        Task {
            await taskVM.updateGoalTask(
                task,
                name: taskName,
                workingTime: taskDate,
                focusDuration: focusDuration,
                isCompleted: isCompleted,
                modelContext: modelContext
            )
            
            dismiss()
        }
    }
}

#Preview {
    let dummyNetworkMonitor = NetworkMonitor()
    let dummyManager = TaskManager(networkMonitor: dummyNetworkMonitor)
    let dummyViewModel = TaskViewModel(networkMonitor: dummyNetworkMonitor)
    
    let sampleGoal = Goal(
        id: "goal-1",
        name: "Sample Goal",
        due: Date().addingTimeInterval(86400),
        goalDescription: "This is a demo goal."
    )
    
    let sampleTask = GoalTask(
        id: "task-1",
        name: "Sample Task",
        workingTime: Date(),
        focusDuration: 60,
        isCompleted: false,
        goal: sampleGoal
    )
    
    return DetailTaskView(
        task: sampleTask,
        taskManager: dummyManager,
        viewModel: dummyViewModel
    )
    .modelContainer(for: [Goal.self, GoalTask.self])
}
