//
//  AddTaskToExistingGoalView.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 06/11/25.
//


import SwiftUI
import SwiftData

struct AddTaskToExistingGoalView: View {
    let goal: Goal
    @ObservedObject var taskVM: TaskViewModel
    @ObservedObject var mainVM: MainViewModel
    var onTasksAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isShowingModalCreateWithAI: Bool = false
    @State private var isShowingModalCreateManually: Bool = false
    @State private var editingTask: AIGoalTask? = nil
    @State private var removingTaskIds: Set<String> = []
    @State private var showDeleteAlert = false
    @State private var taskToDelete: AIGoalTask?
    
    private var allGroupedTasks: [(date: Date, tasks: [GoalTask])] {
        var allTasks = goal.tasks
        let newGoalTasks = taskVM.tasks.map { aiTask -> GoalTask in
            let workingDate = ISO8601DateFormatter.parse(aiTask.workingTime) ?? Date()
            return taskVM.toGoalTask(
                from: aiTask,
                workingDate: workingDate,
                goalName: goal.name,
                goalDeadline: goal.due
            )
        }
        
        allTasks.append(contentsOf: newGoalTasks)
        
        let grouped = Dictionary(grouping: allTasks) { task in
            Calendar.current.startOfDay(for: task.workingTime)
        }
        
        return grouped.map { (date: $0.key, tasks: $0.value.sorted { $0.workingTime < $1.workingTime }) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Goal Info").font(.headline).foregroundColor(.secondary)) {
                    HStack {
                        Text("Goal").foregroundStyle(.secondary)
                        Spacer()
                        Text(goal.name).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Deadline").foregroundStyle(.secondary)
                        Spacer()
                        Text("\(goal.due.formatted(date: .long, time: .omitted)) | \(goal.due.formatted(date: .omitted, time: .shortened))")
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if taskVM.isLoading {
                    Section {
                        ProgressView("Generating AI tasks...")
                            .padding(.vertical)
                            .listRowBackground(Color.clear)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                if let error = taskVM.errorMessage {
                    Section {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding(.vertical)
                    }
                }
                
                if !allGroupedTasks.isEmpty {
                    ForEach(allGroupedTasks, id: \.date) { group in
                        Section(header:
                            Text(group.date, format: .dateTime.day().month(.wide).year())
                            .font(.title3)
                            .foregroundColor(.black)
                        ) {
                            ForEach(group.tasks) { task in
                                // Check if this is a new task (from AI)
                                let isNewTask = taskVM.tasks.contains { aiTask in
                                    aiTask.id == task.id || aiTask.name == task.name
                                }
                                
                                TaskCardView(task: task)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .opacity(removingTaskIds.contains(task.id) ? 0 : 1)
                                    .offset(y: removingTaskIds.contains(task.id) ? -10 : 0)
                                    .if(isNewTask) { view in
                                        view
                                            .onTapGesture {
                                                if let aiTask = taskVM.tasks.first(where: { $0.name == task.name }) {
                                                    editingTask = aiTask
                                                    isShowingModalCreateManually = true
                                                }
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button {
                                                    if let aiTask = taskVM.tasks.first(where: { $0.name == task.name }) {
                                                        taskToDelete = aiTask
                                                        showDeleteAlert = true
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                                .tint(.red)
                                            }
                                    }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .animation(.easeInOut(duration: 0.3), value: taskVM.tasks)
            .animation(.easeInOut(duration: 0.3), value: removingTaskIds)
            
            VStack(spacing: 16) {
                Button(action: { isShowingModalCreateWithAI = true }) {
                    Text("Create with AI")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.15, green: 0.45, blue: 1.0),
                                    Color(red: 0.30, green: 0.95, blue: 1.0),
                                    Color(red: 0.80, green: 0.50, blue: 1.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { isShowingModalCreateManually = true }) {
                    Text("Create Task Manually")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Add Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await taskVM.createAllGoalTasks(for: goal, modelContext: modelContext)
                        
                        await MainActor.run {
                            mainVM.appendNewTasks(goal.tasks)
                            onTasksAdded()
                            dismiss()
                        }
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(taskVM.tasks.isEmpty)
            }
        }
        .background(Color.gray.opacity(0.2).ignoresSafeArea())
        
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                taskToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    deleteTaskWithAnimation(task)
                }
            }
        } message: {
            if let task = taskToDelete {
                Text("Are you sure you want to delete '\(task.name)'? This action cannot be undone.")
            }
        }
        
        .sheet(isPresented: $isShowingModalCreateWithAI) {
            NavigationStack {
                GenerateTaskWithAIView(
                    goalName: goal.name,
                    goalDeadline: goal.due
                ) { description in
                    Task {
                        await taskVM.generateTaskWithAI(
                            for: goal.name,
                            goalDescription: description,
                            goalDeadline: goal.due
                        )
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $isShowingModalCreateManually, onDismiss: {
            editingTask = nil
        }) {
            if let taskToEdit = editingTask {
                CreateTaskManuallyView(taskVM: taskVM, existingTask: taskToEdit)
                    .presentationDetents([.medium])
            } else {
                CreateTaskManuallyView(taskVM: taskVM, taskDeadline: goal.due)
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func deleteTaskWithAnimation(_ task: AIGoalTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            removingTaskIds.insert(task.id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            taskVM.deleteTask(task)
            removingTaskIds.remove(task.id)
            taskToDelete = nil
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
