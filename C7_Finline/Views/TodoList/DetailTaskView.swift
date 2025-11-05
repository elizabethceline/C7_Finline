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
    //    @State private var isDeepFocusOn: Bool = false
    @State private var isNudgeMeOn: Bool = true
    
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var focusVM: FocusSessionViewModel
    @State private var isShowingFocusSettings = false
    //@State private var showFocusView: Bool = false
    @State private var isShowingUnsavedChangesAlert = false
    @State private var isShowingDismissAlert = false
    
    let task: GoalTask

    let taskManager: TaskManager
    let onStartFocus: () -> Void
    
    init(task: GoalTask, taskManager: TaskManager, viewModel: TaskViewModel, onStartFocus: @escaping () -> Void) {
        self.task = task
        self.taskVM = viewModel
        self.onStartFocus = onStartFocus
        
        _taskName = State(initialValue: task.name)
        _taskDate = State(initialValue: task.workingTime)
        _focusDuration = State(initialValue: task.focusDuration)
        _isCompleted = State(initialValue: task.isCompleted)
        
    }
    
    private var hasUnsavedChanges: Bool {
        taskName != task.name ||
        focusDuration != task.focusDuration ||
        taskDate != task.workingTime
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
                                    .foregroundColor(.primary)
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
                                    .foregroundColor(.primary)
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
                //                Section {
                //                    HStack(spacing: 16) {
                //                        ToggleCardView(icon: "moon.fill", title: "Deep Focus", isOn: $focusVM.authManager.isEnabled)
                //                        ToggleCardView(icon: "bell.fill", title: "Nudge Me", isOn: $isNudgeMeOn)
                //                    }
                //                    .padding(.vertical, 8)
                //                }
                //                .listRowInsets(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                //                .listRowBackground(Color.clear)
                
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if hasUnsavedChanges {
                            isShowingDismissAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await taskVM.updateGoalTask(
                                task,
                                name: taskName,
                                workingTime: taskDate,
                                focusDuration: focusDuration,
                                isCompleted: isCompleted,
                                modelContext: modelContext
                            )
                        }
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .disabled(taskName.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    if hasUnsavedChanges {
                        isShowingUnsavedChangesAlert = true
                    } else {
                        focusVM.setTask(task, goal: task.goal)
                        //                    focusVM.nudgeMeEnabled = isNudgeMeOn
                        //                    focusVM.startSession()
                        //                    // showFocusView = true
                        //                    onStartFocus()
                        isShowingFocusSettings = true
                    }
                }) {
                    Text("Start Focus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
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
            .sheet(isPresented: $isShowingFocusSettings) {
                FocusSettingsView(
                    isNudgeMeOn: $isNudgeMeOn,
                    onDone: {
                        focusVM.nudgeMeEnabled = isNudgeMeOn
                        isShowingFocusSettings = false
                        focusVM.startSession()
                        onStartFocus()
                    }
                )
                .environmentObject(focusVM)
                .presentationDetents([.height(300)])
            }
            .alert("Unsaved Changes", isPresented: $isShowingUnsavedChangesAlert) {
                Button("Yes") {
                    Task {
                        await taskVM.updateGoalTask(
                            task,
                            name: taskName,
                            workingTime: taskDate,
                            focusDuration: focusDuration,
                            isCompleted: isCompleted,
                            modelContext: modelContext
                        )
                        focusVM.setTask(task, goal: task.goal)
                        isShowingFocusSettings = true
                    }
                }
                Button("No", role: .cancel) { }
            } message: {
                Text("There's unsaved changes, do you want to save and start focus?")
            }
            .alert("Unsaved Changes", isPresented: $isShowingDismissAlert) {
                Button("Save") {
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
                Button {
                    dismiss()
                } label: {
                    Text("Close Anyway")
                        .foregroundColor(.red)
                }
            } message: {
                Text("There's unsaved changes, do you want to save before closing?")
            }
            
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
    let mockFocusVM = FocusSessionViewModel()
    
    return DetailTaskView(
        task: sampleTask,
        taskManager: dummyManager,
        viewModel: dummyViewModel,
        onStartFocus: { print("Preview Start Focus Tapped") }
    )
    .modelContainer(for: [Goal.self, GoalTask.self])
    .environmentObject(mockFocusVM)
}
