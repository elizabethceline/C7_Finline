//
//  EditGoalView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 01/11/25.
//

import SwiftUI
import FoundationModels
import SwiftData

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var goalVM: GoalViewModel
    
    @State private var goalName: String
    @State private var goalDeadline: Date
    
    private var goal: Goal
    
    @State private var isShowingDatePicker = false
    @State private var isShowingTimePicker = false

    init(goalVM: GoalViewModel, goal: Goal) {
        self.goalVM = goalVM
        self.goal = goal
        _goalName = State(initialValue: goal.name)
        _goalDeadline = State(initialValue: goal.due)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal Name", text: $goalName)
                        .font(.body)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                } header: {
                    Text("Goal")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        isShowingDatePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(goalDeadline.formatted(date: .long, time: .omitted))
                                    .font(.body)
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundStyle(Color.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.black)
                    }

                    Button {
                        isShowingTimePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text(goalDeadline.formatted(date: .omitted, time: .shortened))
                                    .font(.body)
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundStyle(Color.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.black)
                    }
                } header: {
                    Text("Schedule")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Goal")
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
                        goalVM.updateGoal(
                            goal: goal,
                            name: goalName,
                            deadline: goalDeadline,
                            description: nil 
                        )
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(goalName.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingDatePicker) {
                DateTimePickerView(
                    title: "Select Date",
                    selection: $goalDeadline,
                    displayedComponents: [.date]
                )
            }
            .sheet(isPresented: $isShowingTimePicker) {
                DateTimePickerView(
                    title: "Select Time",
                    selection: $goalDeadline,
                    displayedComponents: [.hourAndMinute]
                )
            }
        }
    }
}

#Preview {
    let sampleGoal = Goal(
        id: UUID().uuidString,
        name: "Finish Thesis Chapter 4",
        due: Calendar.current.date(
            from: DateComponents(year: 2025, month: 11, day: 10, hour: 18, minute: 0)
        )!,
        goalDescription: "Write and finalize the discussion section."
    )

    let goalVM = GoalViewModel()

    return NavigationStack {
        EditGoalView(goalVM: goalVM, goal: sampleGoal)
    }
}
