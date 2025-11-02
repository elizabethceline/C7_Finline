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
                        Text("Goal").foregroundStyle(.secondary)
                        Spacer()
                        Text(goalName).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Deadline").foregroundStyle(.secondary)
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
                    ForEach(taskVM.groupedGoalTaskAI(), id: \.date) { group in
                        Section(header:
                            Text(group.date, format: .dateTime.day().month(.wide).year())
                            .font(.title3)
                                .foregroundColor(.primary)
                        ) {
                            ForEach(group.tasks) { aiTask in
                                let workingDate: Date? = ISO8601DateFormatter.parse(aiTask.workingTime)
                                let finalWorkingDate = workingDate ?? Date()
                                let goalTask = taskVM.toGoalTask(from: aiTask, workingDate: finalWorkingDate, goalName: goalName, goalDeadline: goalDeadline)
                                
                                
                                TaskCardView(task: goalTask)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .onTapGesture {
                                        editingTask = aiTask
                                        isShowingModalCreateManually = true
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            withAnimation(.easeInOut) {
                                                taskVM.deleteTask(aiTask)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .tint(.red)
                                    }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            
            VStack(spacing: 16) {
                Button(action: { isShowingModalCreateWithAI = true }) {
                    Text("Create with AI")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { isShowingModalCreateManually = true }) {
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
                        let goal = await goalVM.createGoal(
                            name: goalName,
                            deadline: goalDeadline,
                            description: "",
                            modelContext: modelContext
                        )
                        await taskVM.createAllGoalTasks(for: goal, modelContext: modelContext)
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
                CreateTaskManuallyView(taskVM: taskVM, existingTask: taskToEdit)
                    .presentationDetents([.medium])
            } else {
                CreateTaskManuallyView(taskVM: taskVM, taskDeadline: goalDeadline)
                    .presentationDetents([.medium])
            }
        }
    }
}

extension CreateTaskView {
    static var previewWithDummyTasks: some View {
        let view = CreateTaskView(
            goalName: "Finish SwiftUI Project",
            goalDeadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        )
        
        view.taskVM.tasks = [
            AIGoalTask(id: "1", name: "Design UI Layout", workingTime: "09.00", focusDuration: 60),
            AIGoalTask(id: "2", name: "Implement Login Feature", workingTime: "11.00", focusDuration: 90),
            AIGoalTask(id: "3", name: "Test & Debug", workingTime: "14.00", focusDuration: 45)
        ]
        
        return NavigationStack { view }
    }
}

#Preview {
    CreateTaskView.previewWithDummyTasks
        .preferredColorScheme(.light)
}
