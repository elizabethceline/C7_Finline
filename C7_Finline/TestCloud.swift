//
//  TestCloud.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 22/10/25.
//

// page ini cuma buat aku testing!!!

import SwiftUI
import CloudKit
import Combine

// model
struct UserProfile: Identifiable {
    let id: String
    let recordID: CKRecord.ID
    var username: String
    var points: Int
    var wakeUpTime: Date?
    var sleepTime: Date?

    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.recordID = record.recordID
        self.username = record["username"] as? String ?? ""
        self.points = record["points"] as? Int ?? 0
        self.wakeUpTime = record["wake_up_time"] as? Date
        self.sleepTime = record["sleep_time"] as? Date
    }

    func toRecord(_ record: CKRecord) -> CKRecord {
        record["username"] = username as CKRecordValue
        record["points"] = points as CKRecordValue
        if let wake = wakeUpTime { record["wake_up_time"] = wake as CKRecordValue } else { record["wake_up_time"] = nil }
        if let sleep = sleepTime { record["sleep_time"] = sleep as CKRecordValue } else { record["sleep_time"] = nil }
        return record
    }
}

struct Goal: Identifiable {
    let id: String
    let recordID: CKRecord.ID
    var name: String
    var due: Date
    var description: String?
    let userId: String
    
    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.recordID = record.recordID
        self.name = record["name"] as? String ?? ""
        self.due = record["due"] as? Date ?? Date()
        self.description = record["description"] as? String
        self.userId = record["user_id"] as? String ?? ""
    }
}

struct Task: Identifiable {
    let id: String
    let recordID: CKRecord.ID
    var name: String
    var workingTime: Date
    var focusDuration: Int
    var isCompleted: Bool
    let goalId: String
    
    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.recordID = record.recordID
        self.name = record["name"] as? String ?? ""
        self.workingTime = record["working_time"] as? Date ?? Date()
        self.focusDuration = record["focus_duration"] as? Int ?? 0
        self.isCompleted = record["is_completed"] as? Int == 1
        self.goalId = record["goal_id"] as? String ?? ""
    }
}

// cloudkit manager
class CloudKitManager: ObservableObject {
    @Published var isSignedInToiCloud = false
    @Published var username: String = ""
    @Published var error: String = ""
    @Published var goals: [Goal] = []
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    
    @Published var points: Int = 0
    @Published var wakeUpTime: Date = Date()
    @Published var sleepTime: Date = Date()
    @Published var userProfile: UserProfile?
    
    private let database = CKContainer.default().privateCloudDatabase
    private var userId: String = ""
    
    init() {
        getiCloudStatus()
        fetchUserProfile()
    }
    
    // check icloud account
    private func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isSignedInToiCloud = true
                case .noAccount:
                    self?.error = "No iCloud account found."
                case .couldNotDetermine:
                    self?.error = "Could not determine iCloud status."
                case .restricted:
                    self?.error = "iCloud account restricted."
                default:
                    self?.error = "Unknown iCloud error."
                }
            }
        }
    }
    
    private func fetchUserProfile() {
        CKContainer.default().fetchUserRecordID { [weak self] userRecordID, error in
            guard let self = self, let userRecordID = userRecordID else { return }
            
            DispatchQueue.main.async {
                self.userId = userRecordID.recordName
                let recordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
                
                self.database.fetch(withRecordID: recordID) { record, _ in
                    DispatchQueue.main.async {
                        if let record = record {
                            let profile = UserProfile(record: record)
                            self.userProfile = profile
                            self.username = profile.username
                            self.points = profile.points
                            if let wakeUp = profile.wakeUpTime { self.wakeUpTime = wakeUp }
                            if let sleep = profile.sleepTime { self.sleepTime = sleep }
                            self.fetchGoals()
                        } else {
                            self.createEmptyUserProfile(recordID: recordID)
                        }
                    }
                }
            }
        }
    }
    
    private func createEmptyUserProfile(recordID: CKRecord.ID) {
        let newRecord = CKRecord(recordType: "UserProfile", recordID: recordID)
        newRecord["username"] = "" as CKRecordValue
        
        database.save(newRecord) { _, _ in
            DispatchQueue.main.async {
                self.username = ""
            }
        }
    }
    
    func saveUsername(name: String) {
        CKContainer.default().fetchUserRecordID { [weak self] userRecordID, error in
            guard let self = self, let userRecordID = userRecordID else { return }
            
            let recordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
            
            self.database.fetch(withRecordID: recordID) { record, _ in
                let recordToSave = record ?? CKRecord(recordType: "UserProfile", recordID: recordID)
                recordToSave["username"] = name as CKRecordValue
                
                self.database.save(recordToSave) { _, error in
                    DispatchQueue.main.async {
                        if error == nil {
                            self.username = name
                        }
                    }
                }
            }
        }
    }
    
    func saveUserProfile(username: String, wakeUpTime: Date, sleepTime: Date) {
        CKContainer.default().fetchUserRecordID { [weak self] userRecordID, error in
            guard let self = self, let userRecordID = userRecordID else { return }
            
            let recordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
            
            self.database.fetch(withRecordID: recordID) { record, _ in
                let recordToSave = record ?? CKRecord(recordType: "UserProfile", recordID: recordID)
                var profile = self.userProfile ?? UserProfile(record: recordToSave)
                profile.username = username
                profile.wakeUpTime = wakeUpTime
                profile.sleepTime = sleepTime
                let finalRecord = profile.toRecord(recordToSave)
                self.database.save(finalRecord) { savedRecord, error in
                    DispatchQueue.main.async {
                        if error == nil, let savedRecord = savedRecord {
                            let updated = UserProfile(record: savedRecord)
                            self.userProfile = updated
                            self.username = updated.username
                            if let wake = updated.wakeUpTime { self.wakeUpTime = wake }
                            if let sleep = updated.sleepTime { self.sleepTime = sleep }
                        }
                    }
                }
            }
        }
    }
    
    func addPoints(amount: Int) {
        CKContainer.default().fetchUserRecordID { [weak self] userRecordID, error in
            guard let self = self, let userRecordID = userRecordID else { return }
            
            let recordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
            
            self.database.fetch(withRecordID: recordID) { record, _ in
                guard let recordToSave = record else { return }
                let currentPoints = recordToSave["points"] as? Int ?? 0
                recordToSave["points"] = (currentPoints + amount) as CKRecordValue
                
                self.database.save(recordToSave) { _, error in
                    DispatchQueue.main.async {
                        if error == nil {
                            let newPoints = currentPoints + amount
                            self.points = newPoints
                            if var profile = self.userProfile {
                                profile.points = newPoints
                                self.userProfile = profile
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setPoints(_ points: Int) {
        CKContainer.default().fetchUserRecordID { [weak self] userRecordID, error in
            guard let self = self, let userRecordID = userRecordID else { return }
            let recordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
            self.database.fetch(withRecordID: recordID) { record, _ in
                guard let recordToSave = record else { return }
                var profile = self.userProfile ?? UserProfile(record: recordToSave)
                profile.points = points
                let finalRecord = profile.toRecord(recordToSave)
                self.database.save(finalRecord) { savedRecord, error in
                    DispatchQueue.main.async {
                        if error == nil, let savedRecord = savedRecord {
                            let updated = UserProfile(record: savedRecord)
                            self.userProfile = updated
                            self.points = updated.points
                        }
                    }
                }
            }
        }
    }
    
    // crud goal
    func fetchGoals() {
        isLoading = true
        let predicate = NSPredicate(format: "user_id == %@", userId)
        let query = CKQuery(recordType: "Goals", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "due", ascending: true)]
        
        database.fetch(withQuery: query, inZoneWith: nil) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let result):
                    self.goals = result.matchResults.compactMap { _, result in
                        try? result.get()
                    }.map { Goal(record: $0) }
                    self.fetchAllTasks()
                case .failure(let error):
                    self.error = "Failed to fetch goals: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func createGoal(name: String, due: Date, description: String?) {
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: "Goals", recordID: recordID)
        record["name"] = name as CKRecordValue
        record["due"] = due as CKRecordValue
        record["user_id"] = userId as CKRecordValue
        if let desc = description, !desc.isEmpty {
            record["description"] = desc as CKRecordValue
        }
        
        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = "Failed to create goal: \(error.localizedDescription)"
                } else if let savedRecord = savedRecord {
                    self.goals.append(Goal(record: savedRecord))
                    self.goals.sort { $0.due < $1.due }
                }
            }
        }
    }
    
    func updateGoal(goal: Goal, name: String, due: Date, description: String?) {
        database.fetch(withRecordID: goal.recordID) { record, _ in
            guard let record = record else { return }
            
            record["name"] = name as CKRecordValue
            record["due"] = due as CKRecordValue
            if let desc = description, !desc.isEmpty {
                record["description"] = desc as CKRecordValue
            } else {
                record["description"] = nil
            }
            
            self.database.save(record) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.error = "Failed to update goal: \(error.localizedDescription)"
                    } else if let savedRecord = savedRecord {
                        if let index = self.goals.firstIndex(where: { $0.id == goal.id }) {
                            self.goals[index] = Goal(record: savedRecord)
                            self.goals.sort { $0.due < $1.due }
                        }
                    }
                }
            }
        }
    }
    
    func deleteGoal(goal: Goal) {
        database.delete(withRecordID: goal.recordID) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = "Failed to delete goal: \(error.localizedDescription)"
                } else {
                    self.goals.removeAll { $0.id == goal.id }
                    self.tasks.removeAll { $0.goalId == goal.id }
                }
            }
        }
    }
    
    // crud task
    func fetchAllTasks() {
        let goalIds = goals.map { $0.id }
        guard !goalIds.isEmpty else { return }
        
        let predicate = NSPredicate(format: "goal_id IN %@", goalIds)
        let query = CKQuery(recordType: "Tasks", predicate: predicate)
        
        database.fetch(withQuery: query, inZoneWith: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let result):
                    self.tasks = result.matchResults.compactMap { _, result in
                        try? result.get()
                    }.map { Task(record: $0) }
                case .failure(let error):
                    self.error = "Failed to fetch tasks: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func createTask(goalId: String, name: String, workingTime: Date, focusDuration: Int) {
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: "Tasks", recordID: recordID)
        record["name"] = name as CKRecordValue
        record["working_time"] = workingTime as CKRecordValue
        record["focus_duration"] = focusDuration as CKRecordValue
        record["is_completed"] = 0 as CKRecordValue
        record["goal_id"] = goalId as CKRecordValue
        
        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = "Failed to create task: \(error.localizedDescription)"
                } else if let savedRecord = savedRecord {
                    self.tasks.append(Task(record: savedRecord))
                }
            }
        }
    }
    
    func updateTask(task: Task, name: String, workingTime: Date, focusDuration: Int, isCompleted: Bool) {
        database.fetch(withRecordID: task.recordID) { record, _ in
            guard let record = record else { return }
            
            record["name"] = name as CKRecordValue
            record["working_time"] = workingTime as CKRecordValue
            record["focus_duration"] = focusDuration as CKRecordValue
            record["is_completed"] = (isCompleted ? 1 : 0) as CKRecordValue
            
            self.database.save(record) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.error = "Failed to update task: \(error.localizedDescription)"
                    } else if let savedRecord = savedRecord {
                        if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                            self.tasks[index] = Task(record: savedRecord)
                        }
                    }
                }
            }
        }
    }
    
    func toggleTaskCompletion(task: Task) {
        updateTask(task: task, name: task.name, workingTime: task.workingTime, focusDuration: task.focusDuration, isCompleted: !task.isCompleted)
    }
    
    func deleteTask(task: Task) {
        database.delete(withRecordID: task.recordID) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = "Failed to delete task: \(error.localizedDescription)"
                } else {
                    self.tasks.removeAll { $0.id == task.id }
                }
            }
        }
    }
    
    func getTasksForGoal(_ goalId: String) -> [Task] {
        return tasks.filter { $0.goalId == goalId }
    }
}

// view
struct TestCloud: View {
    @StateObject private var manager = CloudKitManager()
    @State private var showingAddGoal = false
    @State private var showingEditProfile = false

    var body: some View {
        NavigationView {
            ZStack {
                if manager.isLoading {
                    ProgressView("Loading...")
                } else {
                    List {
                        Section("Profile") {
                            HStack {
                                Text("Username")
                                Spacer()
                                Text(manager.username.isEmpty ? "Not Set" : manager.username)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Points")
                                Spacer()
                                Text("\(manager.points)")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Wake Up Time")
                                Spacer()
                                Text(manager.wakeUpTime, format: .dateTime.hour().minute())
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Sleep Time")
                                Spacer()
                                Text(manager.sleepTime, format: .dateTime.hour().minute())
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 8) {
                                Button("Edit Profile") {
                                    showingEditProfile = true
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        
                        Section("Goals") {
                            if manager.goals.isEmpty {
                                Text("No goals yet. Tap + to add one.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(manager.goals) { goal in
                                    NavigationLink(destination: GoalDetailView(manager: manager, goal: goal)) {
                                        GoalRowView(goal: goal, taskCount: manager.getTasksForGoal(goal.id).count)
                                    }
                                }
                                .onDelete(perform: deleteGoals)
                            }
                        }
                    }
                }
                
                if !manager.error.isEmpty {
                    VStack {
                        Spacer()
                        Text(manager.error)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .navigationTitle("Ini buat testing!")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(manager: manager)
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(manager: manager)
            }
        }
    }
    
    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            manager.deleteGoal(goal: manager.goals[index])
        }
    }
}

// goal row
struct GoalRowView: View {
    let goal: Goal
    let taskCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.name)
                .font(.headline)
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(goal.due, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(goal.due, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(taskCount) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let desc = goal.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(dueDate, format: .dateTime.day().month().year())
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
                        let desc = description.isEmpty ? nil : description
                        manager.createGoal(name: name, due: dueDate, description: desc)
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
    
    var tasks: [Task] {
        manager.getTasksForGoal(goal.id)
    }
    
    var body: some View {
        List {
            Section("Goal Info") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(goal.name)
                        .font(.title2)
                        .bold()
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Due Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(goal.due, format: .dateTime.day().month().year())
                                .font(.subheadline)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text("Due Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(goal.due, format: .dateTime.hour().minute())
                                .font(.subheadline)
                        }
                    }
                    
                    if let desc = goal.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(desc)
                                .font(.body)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                Button("Edit Goal") {
                    showingEditGoal = true
                }
            }
            
            Section("Tasks (\(tasks.count))") {
                if tasks.isEmpty {
                    Text("No tasks yet. Tap + to add one.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(tasks) { task in
                        TaskRowView(task: task, manager: manager)
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
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
        for index in offsets {
            manager.deleteTask(task: tasks[index])
        }
    }
}

// task row
struct TaskRowView: View {
    let task: Task
    @ObservedObject var manager: CloudKitManager
    @State private var showingEditTask = false
    
    var body: some View {
        HStack {
            Button(action: { manager.toggleTaskCompletion(task: task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.name)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text("\(task.focusDuration) min")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(task.workingTime, format: .dateTime.day().month().year())
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(task.workingTime, format: .dateTime.hour().minute())
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Button(action: { showingEditTask = true }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(manager: manager, task: task)
        }
    }
}

// add task
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
                    
                    DatePicker("Working Date & Time", selection: $workingTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                    Stepper("Focus Duration: \(focusDuration) min", value: $focusDuration, in: 5...180, step: 5)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(workingTime, format: .dateTime.day().month().year())
                        }
                        .font(.caption)
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text(workingTime, format: .dateTime.hour().minute())
                        }
                        .font(.caption)
                        
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                            Text("\(focusDuration) minutes focus time")
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.createTask(goalId: goalId, name: name, workingTime: workingTime, focusDuration: focusDuration)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// edit goal
struct EditGoalView: View {
    @ObservedObject var manager: CloudKitManager
    let goal: Goal
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var dueDate = Date()
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)
                    
                    DatePicker("Due Date & Time", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(dueDate, format: .dateTime.day().month().year())
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
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let desc = description.isEmpty ? nil : description
                        manager.updateGoal(goal: goal, name: name, due: dueDate, description: desc)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = goal.name
                dueDate = goal.due
                description = goal.description ?? ""
            }
        }
    }
}

// edit task
struct EditTaskView: View {
    @ObservedObject var manager: CloudKitManager
    let task: Task
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var workingTime = Date()
    @State private var focusDuration = 30
    @State private var isCompleted = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Name", text: $name)
                    
                    DatePicker("Working Date & Time", selection: $workingTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                    Stepper("Focus Duration: \(focusDuration) min", value: $focusDuration, in: 5...180, step: 5)
                    
                    Toggle("Completed", isOn: $isCompleted)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(workingTime, format: .dateTime.day().month().year())
                        }
                        .font(.caption)
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text(workingTime, format: .dateTime.hour().minute())
                        }
                        .font(.caption)
                        
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                            Text("\(focusDuration) minutes focus time")
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.updateTask(task: task, name: name, workingTime: workingTime, focusDuration: focusDuration, isCompleted: isCompleted)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
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
    @State private var wakeUp: Date = Date()
    @State private var sleep: Date = Date()
    @State private var pointsText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    TextField("Username", text: $username)
                    TextField("Points", text: $pointsText)
                        .keyboardType(.numberPad)
                }
                Section("Schedule") {
                    DatePicker("Wake Up", selection: $wakeUp, displayedComponents: [.hourAndMinute])
                    DatePicker("Sleep", selection: $sleep, displayedComponents: [.hourAndMinute])
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let pts = Int(pointsText) ?? manager.points
                        manager.saveUserProfile(username: username, wakeUpTime: wakeUp, sleepTime: sleep)
                        manager.setPoints(pts)
                        dismiss()
                    }
                    .disabled(username.isEmpty)
                }
            }
            .onAppear {
                username = manager.username
                wakeUp = manager.wakeUpTime
                sleep = manager.sleepTime
                pointsText = String(manager.points)
            }
        }
    }
}

#Preview {
    TestCloud()
}
