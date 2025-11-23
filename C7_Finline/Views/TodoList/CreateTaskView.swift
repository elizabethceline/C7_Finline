//
//  CreateTaskView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import FoundationModels
import Lottie
import SwiftData
import SwiftUI
import TipKit

struct CreateTaskView: View {
    let goalName: String
    let goalDeadline: Date
    
    @Environment(\.dismiss) private var dismiss
    var dismissParent: DismissAction? = nil
    
    @ObservedObject var mainVM: MainViewModel
    
    @State private var isShowingModalCreateWithAI: Bool = false
    @State private var isShowingModalCreateManually: Bool = false
    @State private var editingTask: AIGoalTask? = nil
    @State private var removingTaskIds: Set<String> = []
    @State private var showDeleteAlert = false
    @State private var taskToDelete: AIGoalTask?

    //    @State private var animate: Bool = false

    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var goalVM = GoalViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme

    private var isAIAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(
                    header: Text("Goal Info").font(.headline).foregroundColor(
                        Color(.gray)
                    )
                ) {
                    HStack {
                        Text("Goal").foregroundStyle(.secondary)
                        Spacer()
                        Text(goalName).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Deadline").foregroundStyle(.secondary)
                        Spacer()
                        Text(
                            "\(goalDeadline.formatted(date: .long, time: .omitted)) | \(goalDeadline.formatted(date: .omitted, time: .shortened))"
                        )
                        .multilineTextAlignment(.trailing)
                    }
                }
                
                if taskVM.isLoading {
                    Section {
                        VStack {
                            //                            Image("finley")
                            //                                .resizable()
                            //                                .scaledToFit()
                            //                                .frame(width: 40, height: 40)
                            //                                .padding(.bottom, 8)
                            //                                .offset(y: animate ? -10 : 10)
                            //                                .animation(
                            //                                    .easeInOut(duration: 0.6).repeatForever(
                            //                                        autoreverses: true
                            //                                    ),
                            //                                    value: animate
                            //                                )
                            LottieView(name: "WritingAnimated", loopMode: .loop)
                                .allowsHitTesting(false)
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-25))
                                .offset(y: 0)

                            Text("Generating AI tasks...")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            //                                .offset(y: animate ? -10 : 10)
                            //                                .animation(
                            //                                    .easeInOut(duration: 0.6).repeatForever(
                            //                                        autoreverses: true
                            //                                    ),
                            //                                    value: animate
                            //                                )
                        }
                        .padding(.vertical)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity, alignment: .center)
                        //                        .onAppear {
                        //                            animate = true
                        //                        }
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
                        Section(
                            header:
                                Text(
                                    group.date,
                                    format: .dateTime.day().month(.wide).year()
                                )
                                .font(.title3)
                                .foregroundColor(Color(.label))
                        ) {
                            ForEach(group.tasks) { aiTask in
                                let workingDate: Date? =
                                ISO8601DateFormatter.parse(
                                    aiTask.workingTime
                                )
                                let finalWorkingDate = workingDate ?? Date()
                                let goalTask = taskVM.toGoalTask(
                                    from: aiTask,
                                    workingDate: finalWorkingDate,
                                    goalName: goalName,
                                    goalDeadline: goalDeadline
                                )
                                
                                TaskCardView(task: goalTask)
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: 8,
                                            leading: 0,
                                            bottom: 8,
                                            trailing: 0
                                        )
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .opacity(
                                        removingTaskIds.contains(aiTask.id)
                                        ? 0 : 1
                                    )
                                    .offset(
                                        y: removingTaskIds.contains(aiTask.id)
                                        ? -10 : 0
                                    )
                                    .onTapGesture {
                                        editingTask = aiTask
                                        isShowingModalCreateManually = true
                                    }
                                    .swipeActions(
                                        edge: .trailing,
                                        allowsFullSwipe: false
                                    ) {
                                        Button {
                                            taskToDelete = aiTask
                                            showDeleteAlert = true
                                        } label: {
                                            Label(
                                                "Delete",
                                                systemImage: "trash"
                                            )
                                        }
                                        .tint(.red)
                                    }
                            }
                        }
                    }
                } else if !taskVM.isLoading {
                    ContentUnavailableView(
                        "No Tasks Yet",
                        systemImage: "tray",
                        description: Text(
                            "Create tasks manually or use AI to generate tasks automatically."
                        )
                    )
                    .foregroundStyle(
                        .primary
                    )
                    .font(.subheadline)
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }
                
            }
            .scrollContentBackground(.hidden)
            .animation(.easeInOut(duration: 0.3), value: taskVM.tasks)
            .animation(.easeInOut(duration: 0.3), value: removingTaskIds)
            
            VStack(spacing: 16) {
                Button(action: {
                    if isAIAvailable {
                        isShowingModalCreateWithAI = true
                        CreateWithAITip.hasClickedCreateWithAI = true
                    }
                }) {
                    Text("Create with AI")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isAIAvailable
                            ? Color.primary : Color.gray.opacity(0.4)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isAIAvailable)
                .popoverTip(CreateWithAITip(), arrowEdge: .bottom)
                
                Button(action: { isShowingModalCreateManually = true }) {
                    Text("Create Task Manually")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isAIAvailable

                                ? (colorScheme == .light
                                    ? Color(.systemBackground)
                                    : Color(.gray.opacity(0.3)))
                                : Color.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .foregroundColor(isAIAvailable ? Color(.label) : .white)
                        .cornerRadius(10)
                }
                if isAIAvailable {
                    Text(
                        "*With create with AI, tasks will be automatically created based on the goal you’ve set."
                    )
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(
                        "*AI task creation isn’t supported on your device right now."
                    )
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        await taskVM.createAllGoalTasks(
                            for: goal,
                            modelContext: modelContext
                        )
                        
                        await MainActor.run {
                            mainVM.appendNewGoal(goal)
                            mainVM.appendNewTasks(goal.tasks)
                            dismissParent?()
                            
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.3
                            ) {
                                if let firstTask = goal.tasks.sorted(by: {
                                    $0.workingTime < $1.workingTime
                                }).first {
                                    let firstTaskDate = Calendar.current
                                        .startOfDay(for: firstTask.workingTime)
                                    mainVM.updateSelectedDate(firstTaskDate)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(taskVM.tasks.isEmpty)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                await taskVM.loadUserProfile(modelContext: modelContext)
            }
        }
        
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
                Text(
                    "Are you sure you want to delete '\(task.name)'? This action cannot be undone."
                )
            }
        }
        
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
        .sheet(
            isPresented: $isShowingModalCreateManually,
            onDismiss: {
                editingTask = nil
            }
        ) {
            if let taskToEdit = editingTask {
                CreateTaskManuallyView(taskVM: taskVM, existingTask: taskToEdit)
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

extension CreateTaskView {
    static var previewWithDummyTasks: some View {
        let view = CreateTaskView(
            goalName: "Finish SwiftUI Project",
            goalDeadline: Calendar.current.date(
                byAdding: .day,
                value: 3,
                to: Date()
            ) ?? Date(),
            mainVM: MainViewModel()
        )
        
        view.taskVM.tasks = [
            AIGoalTask(
                id: "1",
                name: "Design UI Layout",
                workingTime: "09.00",
                focusDuration: 60
            ),
            AIGoalTask(
                id: "2",
                name: "Implement Login Feature",
                workingTime: "11.00",
                focusDuration: 90
            ),
            AIGoalTask(
                id: "3",
                name: "Test & Debug",
                workingTime: "14.00",
                focusDuration: 45
            ),
        ]
        
        return NavigationStack { view }
    }
}

#Preview {
    CreateTaskView.previewWithDummyTasks
        .preferredColorScheme(.light)
}
