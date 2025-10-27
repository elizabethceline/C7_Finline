//
//  GenerateTaskWithAIView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 26/10/25.
//

import SwiftUI

struct GenerateTaskWithAIView: View {
    @Environment(\.dismiss) private var dismiss
    let goalName: String
    let deadlineDate: Date
    @State private var goalDescription: String = ""
    var onGenerate: ((String) -> Void)? 
    
    var body: some View {
        NavigationStack {
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
                    
                    ZStack(alignment: .topLeading) {
                        if goalDescription.isEmpty {
                            Text("Tulis detail mengenai task kamu di sini...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }
                        
                        TextEditor(text: $goalDescription)
                            .frame(minHeight: 100)
                            .font(.body)
                            .padding(4)
                            .cornerRadius(8)
                    }
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
                        onGenerate?(goalDescription) 
                        dismiss()
                    } label: {
                        Image(systemName: "sparkles")
                    }
                }
            }
        }
    }
}

#Preview {
    GenerateTaskWithAIView(
        goalName: "Merancang Skripsi",
        deadlineDate: Date()
    )
}

