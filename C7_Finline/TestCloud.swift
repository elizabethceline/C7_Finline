//
//  TestCloud.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 22/10/25.
//

// page ini cuma buat aku testing!!!

import CloudKit
import Combine
import Network
import SwiftData
import SwiftUI

struct TestCloud: View {
    @StateObject private var manager = CloudKitManager()
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddGoal = false
    @State private var showingEditProfile = false

    var body: some View {
        NavigationView {
            ZStack {
                if manager.isLoading && manager.goals.isEmpty {
                    ProgressView("Loading...")
                } else {
                    List {
                        // Profile Section
                        Section("Profile") {
                            HStack {
                                Text("Username")
                                Spacer()
                                Text(
                                    manager.username.isEmpty
                                        ? "Not Set" : manager.username
                                )
                                .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Points")
                                Spacer()
                                Text("\(manager.points)")
                                    .foregroundColor(.secondary)
                            }
                            NavigationLink(
                                destination: ProductiveHoursView(
                                    manager: manager
                                )
                            ) {
                                HStack {
                                    Text("Productive Hours")
                                    Spacer()
                                    Text("View Schedule").foregroundColor(
                                        .secondary
                                    )
                                }
                            }
                            Button("Edit Profile") { showingEditProfile = true }
                                .buttonStyle(.borderless)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // Goals Section
                        Section("Goals") {
                            if manager.goals.isEmpty {
                                Text("No goals yet. Tap + to add one.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(manager.goals) { goal in
                                    NavigationLink(
                                        destination: GoalDetailView(
                                            manager: manager,
                                            goal: goal
                                        )
                                    ) {
                                        GoalRowView(
                                            goal: goal,
                                            taskCount: manager.getTasksForGoal(
                                                goal.id
                                            ).count
                                        )
                                    }
                                }
                                .onDelete(perform: deleteGoals)
                            }
                        }
                    }
                    .refreshable {
                        print("Pull to refresh triggered.")
                        manager.fetchUserProfile()
                    }
                }

                // Error View
                if !manager.error.isEmpty {
                    VStack {
                        Spacer()
                        Text(manager.error)
                            .foregroundColor(.white).padding()
                            .background(Color.red).cornerRadius(8).padding()
                            .onTapGesture { manager.error = "" }
                    }
                }
            }
            .navigationTitle("Ini buat testing!")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if manager.isLoading {
                    ToolbarItem(placement: .navigationBarLeading) {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(manager: manager)
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(manager: manager)
            }
            .onAppear { manager.setModelContext(modelContext) }
        }
    }

    private func deleteGoals(at offsets: IndexSet) {
        offsets.map { manager.goals[$0] }.forEach(manager.deleteGoal)
    }
}

struct GoalRowView: View {
    let goal: Goal
    let taskCount: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.name).font(.headline)
            HStack {
                Image(systemName: "calendar").font(.caption).foregroundColor(
                    .blue
                )
                Text(goal.due, format: .dateTime.day().month().year()).font(
                    .caption
                ).foregroundColor(.secondary)
                Image(systemName: "clock").font(.caption).foregroundColor(.blue)
                Text(goal.due, format: .dateTime.hour().minute()).font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(taskCount) tasks").font(.caption).foregroundColor(
                    .secondary
                )
            }
            if let desc = goal.goalDescription, !desc.isEmpty {
                Text(desc).font(.caption).foregroundColor(.secondary).lineLimit(
                    2
                )
            }
            if goal.needsSync {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.triangle.2.circlepath.icloud")
                        .font(.caption).foregroundColor(.orange)
                    Text("Syncing...").font(.caption2).foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// add goal
struct AddGoalView: View {
    @ObservedObject var manager: CloudKitManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var dueDate = Date()
    @State private var description = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)

                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)

                    TextField(
                        "Description (Optional)",
                        text: $description,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(
                                dueDate,
                                format: .dateTime.day().month().year()
                            )
                        }
                        .font(.caption)

                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text(dueDate, format: .dateTime.hour().minute())
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _ = description.isEmpty ? nil : description
                        manager.createGoal(
                            name: name,
                            due: dueDate,
                            description: description.isEmpty ? nil : description
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// goal detail
struct GoalDetailView: View {
    @ObservedObject var manager: CloudKitManager
    let goal: Goal
    @State private var showingAddTask = false
    @State private var showingEditGoal = false

    var tasksForThisGoal: [GoalTask] {
        manager.tasks.filter { $0.goal?.id == goal.id }
            .sorted { $0.workingTime < $1.workingTime }
    }

    var body: some View {
        List {
            Section("Goal Info") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(goal.name).font(.title2).bold()
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "calendar").foregroundColor(
                                    .blue
                                )
                                Text("Due Date").font(.caption).foregroundColor(
                                    .secondary
                                )
                            }
                            Text(
                                goal.due,
                                format: .dateTime.day().month().year()
                            ).font(.subheadline)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "clock").foregroundColor(
                                    .blue
                                )
                                Text("Due Time").font(.caption).foregroundColor(
                                    .secondary
                                )
                            }
                            Text(goal.due, format: .dateTime.hour().minute())
                                .font(.subheadline)
                        }
                    }
                    if let desc = goal.goalDescription, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description").font(.caption).foregroundColor(
                                .secondary
                            )
                            Text(desc).font(.body)
                        }
                    }
                    if goal.needsSync {
                        HStack {
                            Spacer()
                            Image(
                                systemName: "arrow.triangle.2.circlepath.icloud"
                            ).font(.caption).foregroundColor(.orange)
                            Text("Syncing changes...").font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }.padding(.vertical, 4)
                Button("Edit Goal") { showingEditGoal = true }
            }

            Section("Tasks (\(tasksForThisGoal.count))") {
                if tasksForThisGoal.isEmpty {
                    Text("No tasks yet. Tap + to add one.").foregroundColor(
                        .secondary
                    )
                } else {
                    ForEach(tasksForThisGoal) { task in
                        TaskRowView(task: task, manager: manager)
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .navigationTitle("Goal Details").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(manager: manager, goalId: goal.id)
        }
        .sheet(isPresented: $showingEditGoal) {
            EditGoalView(manager: manager, goal: goal)
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        offsets.map { tasksForThisGoal[$0] }.forEach(manager.deleteTask)
    }
}

struct TaskRowView: View {
    let task: GoalTask
    @ObservedObject var manager: CloudKitManager
    @State private var showingEditTask = false
    var body: some View {
        HStack {
            Button {
                manager.toggleTaskCompletion(task: task)
            } label: {
                Image(
                    systemName: task.isCompleted
                        ? "checkmark.circle.fill" : "circle"
                )
                .foregroundColor(task.isCompleted ? .green : .gray)
            }.buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.name).font(.body).strikethrough(task.isCompleted)
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer").font(.caption2)
                        Text("\(task.focusDuration) min").font(.caption)
                    }.foregroundColor(.orange)
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.caption2)
                        Text(task.workingTime, format: .dateTime.day().month())
                            .font(.caption)
                    }.foregroundColor(.blue)
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.caption2)
                        Text(
                            task.workingTime,
                            format: .dateTime.hour().minute()
                        ).font(.caption)
                    }.foregroundColor(.blue)
                }
                if task.needsSync {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.triangle.2.circlepath.icloud")
                            .font(.caption2).foregroundColor(.orange)
                        Text("Syncing...").font(.caption2).foregroundColor(
                            .orange
                        )
                    }
                }
            }
            Spacer()
            Button {
                showingEditTask = true
            } label: {
                Image(systemName: "pencil").foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(manager: manager, task: task)
        }
    }
}

struct AddTaskView: View {
    @ObservedObject var manager: CloudKitManager
    let goalId: String
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var workingTime = Date()
    @State private var focusDuration = 30
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Name", text: $name)
                    DatePicker(
                        "Working Date & Time",
                        selection: $workingTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    Stepper(
                        "Focus Duration: \(focusDuration) min",
                        value: $focusDuration,
                        in: 5...180,
                        step: 5
                    )
                }
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.blue)
                            Text(
                                workingTime,
                                format: .dateTime.day().month().year()
                            )
                        }
                        HStack {
                            Image(systemName: "clock").foregroundColor(.blue)
                            Text(workingTime, format: .dateTime.hour().minute())
                        }
                        HStack {
                            Image(systemName: "timer").foregroundColor(.orange)
                            Text("\(focusDuration) minutes focus time")
                        }
                    }.font(.caption)
                }
            }
            .navigationTitle("New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.createTask(
                            goalId: goalId,
                            name: name,
                            workingTime: workingTime,
                            focusDuration: focusDuration
                        )
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditGoalView: View {
    @ObservedObject var manager: CloudKitManager
    let goal: Goal
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var dueDate: Date = Date()
    @State private var description: String = ""
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)
                    DatePicker(
                        "Due Date & Time",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    TextField(
                        "Description (Optional)",
                        text: $description,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.blue)
                            Text(
                                dueDate,
                                format: .dateTime.day().month().year()
                            )
                        }
                        HStack {
                            Image(systemName: "clock").foregroundColor(.blue)
                            Text(dueDate, format: .dateTime.hour().minute())
                        }
                    }.font(.caption)
                }
            }
            .navigationTitle("Edit Goal").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.updateGoal(
                            goal: goal,
                            name: name,
                            due: dueDate,
                            description: description.isEmpty ? nil : description
                        )
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = goal.name
                dueDate = goal.due
                description = goal.goalDescription ?? ""
            }
        }
    }
}

struct EditTaskView: View {
    @ObservedObject var manager: CloudKitManager
    let task: GoalTask
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var workingTime: Date = Date()
    @State private var focusDuration: Int = 30
    @State private var isCompleted: Bool = false
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Name", text: $name)
                    DatePicker(
                        "Working Date & Time",
                        selection: $workingTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    Stepper(
                        "Focus Duration: \(focusDuration) min",
                        value: $focusDuration,
                        in: 5...180,
                        step: 5
                    )
                    Toggle("Completed", isOn: $isCompleted)
                }
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.blue)
                            Text(
                                workingTime,
                                format: .dateTime.day().month().year()
                            )
                        }
                        HStack {
                            Image(systemName: "clock").foregroundColor(.blue)
                            Text(workingTime, format: .dateTime.hour().minute())
                        }
                        HStack {
                            Image(systemName: "timer").foregroundColor(.orange)
                            Text("\(focusDuration) minutes focus time")
                        }
                    }.font(.caption)
                }
            }
            .navigationTitle("Edit Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.updateTask(
                            task: task,
                            name: name,
                            workingTime: workingTime,
                            focusDuration: focusDuration,
                            isCompleted: isCompleted
                        )
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = task.name
                workingTime = task.workingTime
                focusDuration = task.focusDuration
                isCompleted = task.isCompleted
            }
        }
    }
}

struct EditProfileView: View {
    @ObservedObject var manager: CloudKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var pointsText: String = ""
    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    TextField("Username", text: $username)
                    TextField("Points", text: $pointsText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Profile").navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let pts = Int(pointsText) ?? manager.points
                        manager.saveUserProfile(
                            username: username,
                            productiveHours: manager.productiveHours,
                            points: pts
                        )
                        dismiss()
                    }.disabled(username.isEmpty)
                }
            }
            .onAppear {
                username = manager.username
                pointsText = String(manager.points)
            }
        }
    }
}

struct ProductiveHoursView: View {
    @ObservedObject var manager: CloudKitManager
    @State private var productiveHoursState: [ProductiveHours] = []
    @State private var hasChanges = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach($productiveHoursState, id: \.day) { $dayHours in
                Section(dayHours.day.rawValue) {
                    ForEach(TimeSlot.allCases, id: \.self) { slot in
                        Button {
                            toggleTimeSlot(day: dayHours.day, slot: slot)
                        } label: {
                            HStack {
                                Text("\(slot.rawValue), \(slot.hours)")
                                    .foregroundColor(.primary)
                                Spacer()
                                if dayHours.timeSlots.contains(slot) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Productive Hours")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    manager.saveUserProfile(
                        username: manager.username,
                        productiveHours: productiveHoursState,
                        points: manager.points
                    )
                    hasChanges = false
                    dismiss()
                }
                .disabled(!hasChanges)
            }
        }
        .onAppear {
            productiveHoursState = manager.productiveHours
        }
    }

    private func toggleTimeSlot(day: DayOfWeek, slot: TimeSlot) {
        if let index = productiveHoursState.firstIndex(where: { $0.day == day })
        {
            if productiveHoursState[index].timeSlots.contains(slot) {
                productiveHoursState[index].timeSlots.removeAll { $0 == slot }
            } else {
                productiveHoursState[index].timeSlots.append(slot)
            }
            if !hasChanges { hasChanges = true }
        }
    }
}

#Preview {
    TestCloud()
}
