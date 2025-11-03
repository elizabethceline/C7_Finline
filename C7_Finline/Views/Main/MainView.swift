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

    @State private var selectedDate: Date = Calendar.current.startOfDay(
        for: Date()
    )
    @State private var currentWeekIndex: Int = 0
    @State private var showCreateGoalModal = false

    @State private var isWeekChange: Bool = false

    private var calendar: Calendar { .current }
    private var unfinishedTasks: [GoalTask] { viewModel.unfinishedTasks }

    private func jumpToToday() {
        let today = calendar.startOfDay(for: Date())

        isWeekChange = true
        withAnimation {
            let currentWeek = calendar.dateComponents(
                [.weekOfYear, .yearForWeekOfYear],
                from: calendar.startOfDay(for: Date())
            )
            let targetWeek = calendar.dateComponents(
                [.weekOfYear, .yearForWeekOfYear],
                from: today
            )

            if let diff = calendar.dateComponents(
                [.weekOfYear],
                from: currentWeek,
                to: targetWeek
            ).weekOfYear {
                currentWeekIndex = diff
            } else {
                currentWeekIndex = 0
            }

            selectedDate = today
        }

        DispatchQueue.main.async {
            isWeekChange = false
        }
    }

    private func updateSelectedDateFromWeekChange(oldValue: Int, newValue: Int)
    {
        guard !isWeekChange else { return }

        let delta = newValue - oldValue
        guard delta != 0 else { return }

        if let newDate = calendar.date(
            byAdding: .day,
            value: delta * 7,
            to: selectedDate
        ) {
            selectedDate = newDate
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HeaderView(
                    viewModel: viewModel,
                    unfinishedTasks: unfinishedTasks
                )

                // Date Header
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        Text(
                            selectedDate.formatted(.dateTime.month(.wide)) + " "
                        )
                        .foregroundColor(.primary)

                        Text(selectedDate.formatted(.dateTime.year()))
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    DateWeekPagerView(
                        selectedDate: $selectedDate,
                        weekIndex: $currentWeekIndex,
                        isWeekChange: $isWeekChange
                    )

                    Divider()
                }
                .padding(.horizontal)

                ContentCardView(
                    viewModel: viewModel,
                    selectedDate: $selectedDate
                )
            }
            .padding(.top, 8)
            .background(Color(uiColor: .systemGray6).ignoresSafeArea())
            .onAppear {
                viewModel.setModelContext(modelContext)
                jumpToToday()
            }
            .onChange(of: currentWeekIndex) { oldValue, newValue in
                updateSelectedDateFromWeekChange(
                    oldValue: oldValue,
                    newValue: newValue
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Today") {
                        jumpToToday()
                    }
                    .font(.callout)
                    .fontWeight(.medium)

                    Spacer()

                    Button {
                        showCreateGoalModal.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .padding(.all, 12)
                    }
                }
            }
            .sheet(isPresented: $showCreateGoalModal) {
                CreateGoalView(mainVM: viewModel)
                    .presentationDetents([.large])
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Goal.self, GoalTask.self, UserProfile.self])
}
