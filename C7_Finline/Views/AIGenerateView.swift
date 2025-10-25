//
//  AIGenerateView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 23/10/25.
//
import SwiftUI

struct AIGenerateView: View {
    @State private var tasks: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var viewModel = AIViewModel()
    
    private let goal = "Write Chapter 1 of the thesis"

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎯 Goal")
                        .font(.headline)
                    Text(goal)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                Button(action: generateTasks) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                            Text(tasks.isEmpty ? "Generate Task AI" : "Regenerate Tasks")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                if let errorMessage = errorMessage {
                    Text("Terjadi kesalahan: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if !tasks.isEmpty {
                    List {
                        Section(header: Text("🧠 Hasil AI")) {
                            ForEach(tasks, id: \.self) { task in
                                Text(task)
                                    .padding(6)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else if !isLoading {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Belum ada task yang dihasilkan")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("AI Task Generator")
        }
    }
    
    func generateTasks() {
        isLoading = true
        errorMessage = nil
        tasks = []
        Task {
            do {
                let result = try await viewModel.generateTasks()
                tasks = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    AIGenerateView()
}
