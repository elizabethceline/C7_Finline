//
//  GenerateTaskWithAIView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 26/10/25.
//

import SwiftUI
import TipKit

struct GenerateTaskWithAIView: View {
    @Environment(\.dismiss) private var dismiss
    let goalName: String
    let goalDeadline: Date
    @State private var goalDescription: String = ""
    @State private var isShowingAlert = false
    var onGenerate: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header:
                        Text("Goal Info")
                        .font(.headline)
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
                        Text(
                            "\(goalDeadline.formatted(date: .long, time: .omitted)) | \(goalDeadline.formatted(date: .omitted, time: .shortened))"
                        )
                        .multilineTextAlignment(.trailing)
                    }

                    ZStack(alignment: .topLeading) {
                        if goalDescription.isEmpty {
                            Text("Describe details or context about your goal.")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $goalDescription)
                            .frame(minHeight: 100)
                            .font(.body)
                            .padding(4)
                            .cornerRadius(8)
                            .onChange(of: goalDescription) { _, newValue in
                                if !newValue.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ).isEmpty {
                                    AIPromptTip.hasEnteredPrompt = true
                                }
                            }
                    }
                    .popoverTip(AIPromptTip(), arrowEdge: .bottom)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Generate Task with AI")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
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
                        if goalDescription.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty {
                            isShowingAlert = true
                        } else {
                            onGenerate?(goalDescription)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }

            }
            .alert("No Description Provided", isPresented: $isShowingAlert) {
                Button("Continue") {
                    onGenerate?("")
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "Without giving context, we will only generate the tasks based on your title."
                )
            }
        }
    }
}

#Preview {
    GenerateTaskWithAIView(
        goalName: "Merancang Skripsi",
        goalDeadline: Date()
    )
}
