//
//  CreateTaskView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import SwiftUI

struct CreateTaskView: View {
    let goalName: String
    let deadlineDate: Date
    @State private var isShowingModalCreateWithAI: Bool = false
    @StateObject private var aiViewModel = AITaskGeneratorViewModel()
    
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
                        Text("\(deadlineDate.formatted(date: .long, time: .omitted)) | \(deadlineDate.formatted(date: .omitted, time: .shortened))")
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if aiViewModel.isLoading {
                    Section {
                        ProgressView("Generating AI tasks...")
                            .padding(.vertical)
                            .listRowBackground(Color.clear)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                if let error = aiViewModel.errorMessage {
                    Section {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding(.vertical)
                    }
                }
                
                if !aiViewModel.generatedTasks.isEmpty {
                    Section(header: Text("Generated Tasks")) {
                        VStack(spacing: 12) {
                            ForEach(aiViewModel.generatedTasks) { task in
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
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: aiViewModel.generatedTasks)
                                .frame(maxWidth: .infinity, alignment: .center)
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
                    print("Create Task Manually tapped")
                }) {
                    Text("Create Task Manually")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Create Task")
        .background(Color.gray.opacity(0.2).ignoresSafeArea())
        .sheet(isPresented: $isShowingModalCreateWithAI) {
            NavigationStack {
                GenerateTaskWithAIView(
                    goalName: goalName,
                    deadlineDate: deadlineDate
                ) { description in
                    Task {
                        await aiViewModel.generate(
                            for: goalName,
                            description: description,
                            deadline: deadlineDate
                        )
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}


#Preview {
    NavigationStack {
        CreateTaskView(
            goalName: "Finish SwiftUI Project",
            deadlineDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        )
    }
    .preferredColorScheme(.light)
}
