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

    var body: some View {
        VStack {
            Form {
                Section(header:
                    Text("Goal Info")
                        .font(.headline)
                        .foregroundColor(.secondary)
                ) {
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
        .background(Color.gray.opacity(0.2))
        .sheet(isPresented: $isShowingModalCreateWithAI) {
            NavigationStack {
                GenerateTaskWithAIView(goalName: goalName, deadlineDate: deadlineDate)
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

