//
//  CreateTaskView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import SwiftUI
import SwiftData

struct CreateTaskView: View {
    let goalName: String
    let goalDeadline: Date
    @State private var isShowingModalCreateWithAI: Bool = false
    @State private var isShowingModalCreateManually: Bool = false
    @State private var editingTask: AIGoalTask? = nil
    
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var goalVM = GoalViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Goal Info").font(.headline).foregroundColor(.secondary)) {
                    HStack {
                        Text("Goal")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(goalName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Deadline")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(goalDeadline.formatted(date: .long, time: .omitted)) | \(goalDeadline.formatted(date: .omitted, time: .shortened))")
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
                
                if !taskVM.tasks.isEmpty {
                    Section(header: Text("Generated Tasks")) {
                        VStack(spacing: 12) {
                            ForEach(taskVM.tasks) { task in
                                TaskCardView(task: task)
                                    .onTapGesture {
                                        editingTask = task
                                        isShowingModalCreateManually = true
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: taskVM.tasks)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                
            }
            .scrollContentBackground(.hidden)
            
            VStack(spacing: 16) {
                Button(action: {
                    isShowingModalCreateWithAI = true
                }) {
                    Text("Create with AI")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    isShowingModalCreateManually = true
                }) {
                    Text("Create Task Manually")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: DebugDataView()) {
                    Text("Open Debug Data")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Create Task")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        let goal = await goalVM.createGoal(name: goalName, deadline: goalDeadline, description: "", modelContext: modelContext)
                        await taskVM.saveAllTasks(for: goal, modelContext: modelContext)
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(taskVM.tasks.isEmpty)
            }
        }
        .background(Color.gray.opacity(0.2).ignoresSafeArea())
        
        .sheet(isPresented: $isShowingModalCreateWithAI) {
            NavigationStack {
                GenerateTaskWithAIView(
                    goalName: goalName,
                    goalDeadline: goalDeadline
                ) { description in
                    Task {
                        await taskVM.generateTaskWithAI(
                            for: goalName,
                            goalDescription: description,
                            goalDeadline: goalDeadline
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
                CreateTaskManuallyView(
                    taskVM: taskVM,
                    existingTask: taskToEdit
                )
                .presentationDetents([.medium])
            } else {
                CreateTaskManuallyView(
                    taskVM: taskVM,
                    taskDeadline: goalDeadline
                )
                .presentationDetents([.medium])
            }
        }
    }
    
    struct TaskCardView: View {
        let task: AIGoalTask
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.name)
                    .font(.headline)
                Text("Start: \(task.workingTime), Duration: \(task.focusDuration) mins")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

#Preview {
    NavigationStack {
        CreateTaskView(
            goalName: "Finish SwiftUI Project",
            goalDeadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        )
    }
    .preferredColorScheme(.light)
}
