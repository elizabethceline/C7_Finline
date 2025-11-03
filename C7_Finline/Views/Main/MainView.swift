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

    var calendar: Calendar { .current }

    private var unfinishedTasks: [GoalTask] { viewModel.unfinishedTasks }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HeaderView(
                    viewModel: viewModel,
                    unfinishedTasks: unfinishedTasks
                )

                // Date Header
                DateHeaderView(
                    selectedDate: $selectedDate,
                    currentWeekIndex: $currentWeekIndex,
                    showDatePicker: $showDatePicker,
                    isWeekChange: $isWeekChange,
                    jumpToDate: jumpToDate(_:)
                )

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
                        if showDatePicker {
                            withAnimation(.spring(response: 0.3)) {
                                showDatePicker = false
                            }
                        }
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
