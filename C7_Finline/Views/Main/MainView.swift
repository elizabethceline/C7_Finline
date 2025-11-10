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
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @State private var showCreateGoalModal = false
    @State private var showDatePicker = false

    @State var selectedDate: Date = Calendar.current.startOfDay(
        for: Date()
    )
    @State var currentWeekIndex: Int = 0
    @State var isWeekChange: Bool = false
    @State private var hasAppeared = false

    var calendar: Calendar { .current }

    private var unfinishedTasks: [GoalTask] { viewModel.unfinishedTasks }

    @Query(sort: \Goal.due, order: .forward) private var goals: [Goal]
    @Query private var tasks: [GoalTask]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HeaderView(
                    viewModel: viewModel,
                    unfinishedTasks: unfinishedTasks,
                    selectedDate: $selectedDate
                )

                // Date Header
                DateHeaderView(
                    selectedDate: $selectedDate,
                    currentWeekIndex: $currentWeekIndex,
                    showDatePicker: $showDatePicker,
                    isWeekChange: $isWeekChange,
                    taskFilter: $viewModel.taskFilter,
                    jumpToDate: jumpToDate(_:),
                    unfinishedTasks: unfinishedTasks
                )

                ContentCardView(
                    viewModel: viewModel,
                    goals: goals,
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    networkMonitor: networkMonitor
                )
            }
            .background(Color(uiColor: .systemGray6).ignoresSafeArea())
            .onAppear {
                viewModel.setModelContext(modelContext)
                if !hasAppeared {
                    jumpToToday()
                    hasAppeared = true
                }
                viewModel.goals = goals
                viewModel.tasks = tasks
            }
            .onChange(of: currentWeekIndex) { oldValue, newValue in
                updateSelectedDateFromWeekChange(
                    oldValue: oldValue,
                    newValue: newValue
                )
            }
            .onChange(of: goals) { _, newGoals in
                viewModel.goals = newGoals
            }
            .onChange(of: tasks) { _, newTasks in
                viewModel.tasks = newTasks
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack(spacing: 12) {
                        Button("Today") {
                            jumpToToday()
                            if showDatePicker {
                                withAnimation(.spring(response: 0.3)) {
                                    showDatePicker = false
                                }
                            }
                        }
                        .font(.callout)
                        .fontWeight(.medium)

                        if !unfinishedTasks.isEmpty {
                            Text("|")
                                .foregroundColor(Color(.label))
                                .padding(.leading, 4)

                            Button {
                                if let oldestTask =
                                    unfinishedTasks
                                    .filter({ $0.workingTime < Date() })
                                    .sorted(by: {
                                        $0.workingTime < $1.workingTime
                                    })
                                    .first
                                {
                                    withAnimation(.spring()) {
                                        selectedDate = Calendar.current
                                            .startOfDay(
                                                for: oldestTask.workingTime
                                            )
                                    }
                                }
                            } label: {
                                Text("Overdue")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                Text("\(unfinishedTasks.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(7)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .fixedSize()
                    .padding(.horizontal, unfinishedTasks.isEmpty ? 0 : 8)

                    Spacer()

                    Button {
                        showCreateGoalModal.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                }
            }

            .sheet(isPresented: $showCreateGoalModal) {
                CreateGoalView(mainVM: viewModel)
                    .presentationDetents([.large])
            }

            .sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { selectedDate },
                            set: { newDate in
                                jumpToDate(newDate)
                            }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.primary)
                    .labelsHidden()
                    .padding()

                    Button("Done") {
                        showDatePicker = false
                    }
                    .foregroundColor(Color.primary)
                    .font(.headline)
                    .padding()
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Goal.self, GoalTask.self, UserProfile.self])
        .environmentObject(NetworkMonitor())
}
