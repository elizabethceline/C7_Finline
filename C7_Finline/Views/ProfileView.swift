//
//  ProfileView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @Environment(\.modelContext) private var modelContext
    @State private var selectedMonth = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // profile
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 28))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.username.isEmpty ? "Your Name" : viewModel.username)
                                .font(.headline)
                            Text("@username")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // monthly report
                    HStack {
                        Text("Monthly report")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text(selectedMonth, format: .dateTime.month())
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Task Complete",
                            value: "\(viewModel.completedTasksThisMonth)"
                        )
                        StatCard(
                            title: "Points Earn",
                            value: "\(viewModel.points)"
                        )
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Done")
                            .font(.headline)
                        
                        Chart {
                            ForEach(generateWeeklyData(), id: \.week) { item in
                                BarMark(
                                    x: .value("Week", item.week),
                                    y: .value("Tasks", item.count)
                                )
                                .foregroundStyle(Color.blue)
                            }
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemGray6))
                    )
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Best Focus Time")
                            .font(.headline)
                        Spacer()
                        Text("12:09:10")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemGray6))
                    )
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Average Focus Time")
                            .font(.headline)
                        
                        Chart {
                            ForEach(focusData) { item in
                                SectorMark(
                                    angle: .value("Hours", item.value),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(item.color)
                                .annotation(position: .overlay) {
                                    Text(item.label)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemGray6))
                    )
                    .padding(.horizontal)
                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func generateWeeklyData() -> [(week: String, count: Int)] {
        return [
            ("W1", 28),
            ("W2", 12),
            ("W3", 3),
            ("W4", 31),
            ("W5", 6)
        ]
    }

    private var focusData: [FocusSegment] {
        [
            .init(label: "Morning", value: 25, color: .blue.opacity(0.8)),
            .init(label: "Night", value: 75, color: .blue)
        ]
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemGray6))
        )
    }
}

struct FocusSegment: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
