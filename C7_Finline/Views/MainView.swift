//
//  MainView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date()

    private var filteredTasks: [GoalTask] {
        viewModel.tasks.filter { task in
            Calendar.current.isDate(task.workingTime, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let headerHeight = geo.size.height * 0.5

            ZStack(alignment: .top) {
                Image("main_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: headerHeight)
                    .clipped()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: headerHeight / 1.5)

                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .systemGray6))
                            .ignoresSafeArea(edges: .bottom)

                        VStack(spacing: 0) {
                            // Date selector
                            dateSelector
                                .padding(.top, 32)

                            Divider()
                                .padding()

                            // Task section
                            if filteredTasks.isEmpty {
                                emptyState
                                    .padding(.top, 24)
                            } else {
                                taskList
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                            }
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // add task
                        }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.blue.opacity(0.4)))
                                .shadow(radius: 2)
                        }
                        .padding(.trailing, 28)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                selectedDate = Calendar.current.startOfDay(for: Date())
            }
        }
    }

    private var dateSelector: some View {
        let days = getDaysOfCurrentWeek()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(
                        selectedDate,
                        inSameDayAs: date
                    )

                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 6) {
                            Text(shortWeekday(from: date))
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))

                            Text(
                                "\(Calendar.current.component(.day, from: date))"
                            )
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        }
                        .frame(width: 60, height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isSelected ? Color.black : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var taskList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if let goal = viewModel.goals.first(where: { goal in
                    goal.tasks.contains {
                        Calendar.current.isDate(
                            $0.workingTime,
                            inSameDayAs: selectedDate
                        )
                    }
                }) {
                    HStack {
                        Text(goal.name)
                            .font(.headline)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.title3)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(50)

                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(50)
                }

                ForEach(filteredTasks) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedTime(task.workingTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(task.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Text("\(task.focusDuration)m")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)

                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedTime(task.workingTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(task.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Text("\(task.focusDuration)m")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)

                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedTime(task.workingTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(task.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Text("\(task.focusDuration)m")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedTime(task.workingTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(task.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Text("\(task.focusDuration)m")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedTime(task.workingTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(task.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Text("\(task.focusDuration)m")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedTime(task.workingTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(task.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Text("\(task.focusDuration)m")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
                }
            }
            
            .padding(.bottom, 48)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image("fish")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("No More Task")
                .font(.headline)
            Text("you may rest...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private func shortWeekday(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func getDaysOfCurrentWeek() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Goal.self, GoalTask.self, UserProfile.self])
}
