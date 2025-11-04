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

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
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
                    selectedDate: $selectedDate
                )
            }
            .background(Color(uiColor: .systemGray6).ignoresSafeArea())
            .onAppear {
                viewModel.setModelContext(modelContext)
                if !hasAppeared {
                    jumpToToday()
                    hasAppeared = true
                }
            }
            .onChange(of: currentWeekIndex) { oldValue, newValue in
                updateSelectedDateFromWeekChange(
                    oldValue: oldValue,
                    newValue: newValue
                )
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
                                .foregroundColor(.black)
                                .padding(.leading, 4)

                            Button {
                                if let firstTask = unfinishedTasks.first {
                                    selectedDate = Calendar.current.startOfDay(
                                        for: firstTask.workingTime
                                    )
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
}
