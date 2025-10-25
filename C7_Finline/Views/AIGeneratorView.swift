//
//  AIGenerateView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//

import SwiftUI

struct AIGeneratorView: View {
    @StateObject private var vm = AITaskGeneratorViewModel()
    private let user = UserProfile(
        id: "user-1",
        username: "Elizabeth",
        points: 200,
        productiveHours: [
            ProductiveHours(day: .monday, timeSlots: [.morning, .afternoon]),
            ProductiveHours(day: .tuesday, timeSlots: [.morning, .evening]),
            ProductiveHours(day: .wednesday, timeSlots: [.afternoon]),
            ProductiveHours(day: .friday, timeSlots: [.morning])
        ]
    )

    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var due: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Form {
                    Section(header: Text("Your Goal")) {
                        TextField("Title", text: $title)
                        TextField("Description", text: $desc)
                        DatePicker("Deadline", selection: $due, displayedComponents: .date)
                    }

                    Section {
                        if vm.isLoading {
                            HStack { Spacer(); ProgressView("Generating..."); Spacer() }
                        } else {
                            Button(action: generate) {
                                Text("Generate Tasks with AI")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .frame(maxHeight: 360)

                Divider()

                if let err = vm.errorMessage {
                    Text("Error: \(err)").foregroundColor(.red)
                }

                if vm.generatedTasks.isEmpty {
                    Text("No tasks generated yet").foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Generated Tasks").font(.headline)
                            ForEach(vm.generatedTasks) { t in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(t.name).bold()
                                    Text("When: \(t.workingTime)")
                                    Text("Focus: \(t.focusDuration) minutes")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("AI Task Generator")
        }
    }

    private func generate() {
        let goal = Goal(id: UUID().uuidString, name: title, due: due, goalDescription: desc)
        Task { await vm.generateTasks(for: goal) }
    }
}
