//
//  CloudKitManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import Foundation
import CloudKit
import Combine
import Network
import SwiftData
import SwiftUI

class CloudKitManager: ObservableObject {
    @Published var isSignedInToiCloud = false
    @Published var username: String = ""
    @Published var error: String = ""
    @Published var goals: [Goal] = []
    @Published var tasks: [GoalTask] = []
    @Published var isLoading = false
    @Published var points: Int = 0
    @Published var productiveHours: [ProductiveHours] = DayOfWeek.allCases.map {
        ProductiveHours(day: $0)
    }
    @Published var userProfile: UserProfile?

    private let database = CKContainer.default().privateCloudDatabase
    private var modelContext: ModelContext?
    private let networkMonitor = NetworkMonitor()
    private var cancellables = Set<AnyCancellable>()

    private let pendingGoalDeletionIDsKey = "pendingGoalDeletionIDs"
    private let pendingTaskDeletionIDsKey = "pendingTaskDeletionIDs"

    init() {
        getiCloudStatus()
        observeNetworkStatus()
    }

    private func observeNetworkStatus() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    print(
                        "Network connected! Attempting to sync pending items..."
                    )
                    if self.isSignedInToiCloud, self.modelContext != nil {
                        self.syncPendingItems()
                    }
                } else {
                    print("Network disconnected.")
                }
            }
            .store(in: &cancellables)
    }

    func setModelContext(_ context: ModelContext) {
        if self.modelContext != nil { return }
        self.modelContext = context
        loadDataFromSwiftData()
        if networkMonitor.isConnected {
            syncPendingItems()
        }
        fetchUserProfile()
    }

    private func loadDataFromSwiftData() {
        guard let modelContext = modelContext else { return }
        do {
            let profileDescriptor = FetchDescriptor<UserProfile>()
            if let profile = (try modelContext.fetch(profileDescriptor)).first {
                updatePublishedProfile(profile)
            }
            let goalDescriptor = FetchDescriptor<Goal>(sortBy: [
                SortDescriptor(\.due, order: .forward)
            ])
            self.goals = try modelContext.fetch(goalDescriptor)
            let taskDescriptor = FetchDescriptor<GoalTask>()
            self.tasks = try modelContext.fetch(taskDescriptor)
        } catch {
            DispatchQueue.main.async {
                self.error =
                    "Failed to load local data: \(error.localizedDescription)"
            }
        }
    }

    private func updatePublishedProfile(_ profile: UserProfile?) {
        self.userProfile = profile
        self.username = profile?.username ?? ""
        self.points = profile?.points ?? 0
        self.productiveHours =
            profile?.productiveHours
            ?? DayOfWeek.allCases.map { ProductiveHours(day: $0) }
    }

    private func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                switch status {
                case .available: self?.isSignedInToiCloud = true
                case .noAccount: self?.error = "No iCloud account found."
                case .couldNotDetermine:
                    self?.error = "Could not determine iCloud status."
                case .restricted: self?.error = "iCloud account restricted."
                default: self?.error = "Unknown iCloud error."
                }
            }
        }
    }

    func fetchUserProfile() {
        guard let modelContext = modelContext, isSignedInToiCloud else {
            return
        }

        CKContainer.default().fetchUserRecordID {
            [weak self] userRecordID, error in
            Task { @MainActor in
                guard let self = self, let userRecordID = userRecordID else {
                    return
                }

                let recordID = CKRecord.ID(
                    recordName: "UserProfile_\(userRecordID.recordName)"
                )
                let targetUserID = userRecordID.recordName
                let profilePredicate = #Predicate<UserProfile> {
                    $0.id == targetUserID
                }
                let localProfile =
                    (try? modelContext.fetch(
                        FetchDescriptor(predicate: profilePredicate)
                    ))?.first

                // fetch cloudkit
                do {
                    let record = try await self.database.record(for: recordID)
                    print("Found user profile in CloudKit.")
                    let ckProfile = UserProfile(record: record)

                    if let existingProfile = localProfile {
                        // update local
                        existingProfile.username = ckProfile.username
                        existingProfile.points = ckProfile.points
                        existingProfile.productiveHoursJSON =
                            ckProfile.productiveHoursJSON
                        existingProfile.needsSync = false
                        self.updatePublishedProfile(existingProfile)
                    } else {
                        // insert local
                        modelContext.insert(ckProfile)
                        self.updatePublishedProfile(ckProfile)
                    }
                    self.fetchGoals()

                } catch let error as CKError where error.code == .unknownItem {
                    // no record
                    print("User profile not found in CloudKit.")
                    if let existingProfile = localProfile {
                        print("Local profile found. Pushing to CloudKit...")
                        existingProfile.needsSync = true
                        await self.syncProfileToCloud(existingProfile)
                        self.updatePublishedProfile(existingProfile)
                        self.fetchGoals()
                    } else {
                        print(
                            "No local profile found. Creating empty profile..."
                        )
                        self.createEmptyUserProfile(
                            recordID: recordID,
                            userRecordIDName: targetUserID
                        )
                    }
                } catch {
                    self.error =
                        "Failed to fetch user profile: \(error.localizedDescription)"
                    print(
                        "Failed to fetch user profile: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    private func createEmptyUserProfile(
        recordID: CKRecord.ID,
        userRecordIDName: String
    ) {
        guard let modelContext = modelContext else { return }

        // create local
        let emptyHours = DayOfWeek.allCases.map { ProductiveHours(day: $0) }
        let newProfile = UserProfile(
            id: userRecordIDName,
            username: "",
            points: 0,
            productiveHours: emptyHours,
            needsSync: true
        )
        modelContext.insert(newProfile)
        self.updatePublishedProfile(newProfile)
        print("Created empty profile locally (needs sync).")

        // push cloud
        Task {
            await syncProfileToCloud(newProfile)
            await MainActor.run { self.fetchGoals() }
        }
    }

    func saveUserProfile(
        username: String,
        productiveHours: [ProductiveHours],
        points: Int
    ) {
        guard modelContext != nil, let userProfile = self.userProfile else {
            return
        }

        // update local
        userProfile.username = username
        userProfile.productiveHours = productiveHours
        userProfile.points = points
        userProfile.needsSync = true
        updatePublishedProfile(userProfile)
        print("Updated profile locally (needs sync).")

        // push cloud
        Task {
            await syncProfileToCloud(userProfile)
        }
    }

    func syncPendingItems() {
        guard let modelContext = modelContext, networkMonitor.isConnected else {
            print("Sync skipped: No model context or not connected.")
            return
        }
        print("Starting syncPendingItems...")

        Task {
            await syncPendingDeletions()

            // sync profile
            let profilePredicate = #Predicate<UserProfile> {
                $0.needsSync == true
            }
            if let profileToSync =
                (try? modelContext.fetch(
                    FetchDescriptor(predicate: profilePredicate)
                ))?.first
            {
                print("Found pending profile sync.")
                await syncProfileToCloud(profileToSync)
            }

            // sync goals
            let goalPredicate = #Predicate<Goal> { $0.needsSync == true }
            let pendingGoalIDsToDelete = getPendingDeletionIDs(
                forKey: pendingGoalDeletionIDsKey
            )
            let pendingGoals =
                (try? modelContext.fetch(
                    FetchDescriptor(predicate: goalPredicate)
                ))?
                .filter { !pendingGoalIDsToDelete.contains($0.id) }

            if let goalsToSync = pendingGoals, !goalsToSync.isEmpty {
                print(
                    "Found \(goalsToSync.count) pending goals to create/update."
                )
                for goal in goalsToSync { await syncGoalToCloud(goal) }
            } else {
                print("No pending goals to create/update.")
            }

            // sync task
            let taskPredicate = #Predicate<GoalTask> { $0.needsSync == true }
            let pendingTaskIDsToDelete = getPendingDeletionIDs(
                forKey: pendingTaskDeletionIDsKey
            )
            let pendingTasks =
                (try? modelContext.fetch(
                    FetchDescriptor(predicate: taskPredicate)
                ))?
                .filter { !pendingTaskIDsToDelete.contains($0.id) }

            if let tasksToSync = pendingTasks, !tasksToSync.isEmpty {
                print(
                    "Found \(tasksToSync.count) pending tasks to create/update."
                )
                for task in tasksToSync { await syncTaskToCloud(task) }
            } else {
                print("No pending tasks to create/update.")
            }

            print("syncPendingItems finished.")
        }
    }

    private func getPendingDeletionIDs(forKey key: String) -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(array)
    }

    private func savePendingDeletionIDs(_ ids: Set<String>, forKey key: String)
    {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }

    private func addPendingDeletionID(_ id: String, forKey key: String) {
        var currentIDs = getPendingDeletionIDs(forKey: key)
        currentIDs.insert(id)
        savePendingDeletionIDs(currentIDs, forKey: key)
        print("Added \(key) to pending deletions: \(id)")
    }

    private func removePendingDeletionID(_ id: String, forKey key: String) {
        var currentIDs = getPendingDeletionIDs(forKey: key)
        if currentIDs.remove(id) != nil {
            savePendingDeletionIDs(currentIDs, forKey: key)
            print("Removed \(key) from pending deletions: \(id)")
        }
    }

    // sync delete
    private func syncPendingDeletions() async {
        guard networkMonitor.isConnected else { return }

        // sync delete goal
        let goalIDsToDelete = getPendingDeletionIDs(
            forKey: pendingGoalDeletionIDsKey
        )
        if !goalIDsToDelete.isEmpty {
            print("Found \(goalIDsToDelete.count) pending goal deletions.")
            for id in goalIDsToDelete {
                await deleteRecordFromCloud(
                    recordName: id,
                    recordType: "Goals",
                    userDefaultsKey: pendingGoalDeletionIDsKey
                )
            }
        } else {
            print("No pending goal deletions.")
        }

        // sync delete task
        let taskIDsToDelete = getPendingDeletionIDs(
            forKey: pendingTaskDeletionIDsKey
        )
        if !taskIDsToDelete.isEmpty {
            print("Found \(taskIDsToDelete.count) pending task deletions.")
            for id in taskIDsToDelete {
                await deleteRecordFromCloud(
                    recordName: id,
                    recordType: "Tasks",
                    userDefaultsKey: pendingTaskDeletionIDsKey
                )
            }
        } else {
            print("No pending task deletions.")
        }
    }

    private func deleteRecordFromCloud(
        recordName: String,
        recordType: String,
        userDefaultsKey: String
    ) async {
        guard networkMonitor.isConnected else { return }
        let recordID = CKRecord.ID(recordName: recordName)
        print("Attempting cloud delete for \(recordType) ID: \(recordName)")

        do {
            try await database.deleteRecord(withID: recordID)
            await MainActor.run {
                removePendingDeletionID(recordName, forKey: userDefaultsKey)
            }
            print(
                "Successfully deleted \(recordType) from cloud: \(recordName)"
            )
        } catch let error as CKError where error.code == .unknownItem {
            print(
                "Record \(recordType) \(recordName) not found in cloud (already deleted?). Removing from pending."
            )
            await MainActor.run {
                removePendingDeletionID(recordName, forKey: userDefaultsKey)
            }
        } catch {
            await MainActor.run {
                self.error =
                    "Failed to delete \(recordType) \(recordName) from cloud (will retry): \(error.localizedDescription)"
                print(
                    "Failed to delete \(recordType) \(recordName) from cloud (will retry): \(error.localizedDescription)"
                )
            }
        }
    }

    private func syncProfileToCloud(_ profile: UserProfile) async {
        guard networkMonitor.isConnected else { return }
        print("Attempting to sync profile for user ID: \(profile.id)")
        let recordID = CKRecord.ID(recordName: "UserProfile_\(profile.id)")

        do {
            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
                print("Found existing profile record in CloudKit.")
            } catch let error as CKError where error.code == .unknownItem {
                print(
                    "No existing profile record in CloudKit, creating new one."
                )
                record = CKRecord(recordType: "UserProfile", recordID: recordID)
            }

            // update record from local
            let finalRecord = profile.toRecord(record)

            try await database.save(finalRecord)

            await MainActor.run {
                profile.needsSync = false
                print("Successfully synced profile.")
            }
        } catch {
            await MainActor.run {
                self.error =
                    "Failed to sync profile: \(error.localizedDescription)"
                print("Failed to sync profile: \(error.localizedDescription)")
            }
        }
    }

    private func syncGoalToCloud(_ goal: Goal) async {
        guard networkMonitor.isConnected else { return }

        // check if this item is deleted/not
        if getPendingDeletionIDs(forKey: pendingGoalDeletionIDsKey).contains(
            goal.id
        ) {
            print(
                "Skipping sync for goal '\(goal.name)' because it is pending deletion."
            )
            return
        }
        print("Attempting to sync goal: \(goal.name)")
        let recordID = CKRecord.ID(recordName: goal.id)
        do {
            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
                print("Found existing record for goal: \(goal.name)")
            } catch let error as CKError where error.code == .unknownItem {
                print(
                    "No existing record for goal \(goal.name), creating new one."
                )
                record = CKRecord(recordType: "Goals", recordID: recordID)
            }

            record["name"] = goal.name as CKRecordValue
            record["due"] = goal.due as CKRecordValue
            record["description"] = goal.goalDescription as CKRecordValue?

            try await database.save(record)
            await MainActor.run {
                goal.needsSync = false
                print("Successfully synced goal: \(goal.name)")
            }
        } catch {
            await MainActor.run {
                self.error =
                    "Failed to sync goal '\(goal.name)': \(error.localizedDescription)"
                print(
                    "Failed to sync goal '\(goal.name)': \(error.localizedDescription)"
                )
            }
        }
    }

    private func syncTaskToCloud(_ task: GoalTask) async {
        guard networkMonitor.isConnected else { return }

        // check if this item is deleted/not
        if getPendingDeletionIDs(forKey: pendingTaskDeletionIDsKey).contains(
            task.id
        ) {
            print(
                "Skipping sync for task '\(task.name)' because it is pending deletion."
            )
            return
        }
        print("Attempting to sync task: \(task.name)")
        guard let goalID = task.goal?.id else {
            print(
                "Cannot sync task '\(task.name)' because its goal is missing."
            )
            return
        }
        let recordID = CKRecord.ID(recordName: task.id)
        do {
            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
                print("Found existing record for task: \(task.name)")
            } catch let error as CKError where error.code == .unknownItem {
                print(
                    "No existing record for task \(task.name), creating new one."
                )
                record = CKRecord(recordType: "Tasks", recordID: recordID)
            }

            record["name"] = task.name as CKRecordValue
            record["working_time"] = task.workingTime as CKRecordValue
            record["focus_duration"] = task.focusDuration as CKRecordValue
            record["is_completed"] = (task.isCompleted ? 1 : 0) as CKRecordValue
            record["goal_id"] = goalID as CKRecordValue

            try await database.save(record)
            await MainActor.run {
                task.needsSync = false
                print("Successfully synced task: \(task.name)")
            }
        } catch {
            await MainActor.run {
                self.error =
                    "Failed to sync task '\(task.name)': \(error.localizedDescription)"
                print(
                    "Failed to sync task '\(task.name)': \(error.localizedDescription)"
                )
            }
        }
    }

    // crud goal
    func fetchGoals() {
        guard let modelContext = modelContext, isSignedInToiCloud,
            networkMonitor.isConnected
        else {
            print("Skipping fetchGoals: Not signed in, no context, or offline.")
            return
        }
        isLoading = true
        let query = CKQuery(
            recordType: "Goals",
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "due", ascending: true)]

        database.fetch(withQuery: query, inZoneWith: nil) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let queryResult):
                    let ckRecords = queryResult.matchResults.compactMap {
                        _,
                        recordResult in try? recordResult.get()
                    }
                    let cloudRecordIDs = Set(
                        ckRecords.map { $0.recordID.recordName }
                    )
                    var syncedGoals: [Goal] = []

                    // sync from cloud
                    for record in ckRecords {
                        let ckGoal = Goal(record: record)
                        let goalID = ckGoal.id
                        let predicate = #Predicate<Goal> {
                            $0.id == goalID
                        }
                        if let existingGoal =
                            (try? modelContext.fetch(
                                FetchDescriptor(predicate: predicate)
                            )).flatMap({ $0.first })
                        {
                            // update
                            existingGoal.name = ckGoal.name
                            existingGoal.due = ckGoal.due
                            existingGoal.goalDescription =
                                ckGoal.goalDescription
                            existingGoal.needsSync = false
                            syncedGoals.append(existingGoal)
                        } else {
                            // insert
                            modelContext.insert(ckGoal)
                            syncedGoals.append(ckGoal)
                        }
                    }

                    // delete local data yang gaada di cloud
                    let localGoalsToDelete = self.goals.filter {
                        !cloudRecordIDs.contains($0.id) && !$0.needsSync
                    }
                    for goalToDelete in localGoalsToDelete {
                        print(
                            "Deleting local goal not found in Cloud: \(goalToDelete.name)"
                        )
                        modelContext.delete(goalToDelete)
                    }

                    self.goals =
                        (try? modelContext.fetch(
                            FetchDescriptor<Goal>(sortBy: [
                                SortDescriptor(\.due, order: .forward)
                            ])
                        )) ?? []
                    self.fetchAllTasks()

                case .failure(let error):
                    self.error =
                        "Failed to fetch goals: \(error.localizedDescription)"
                }
            }
        }
    }

    func createGoal(name: String, due: Date, description: String?) {
        guard let modelContext = modelContext else { return }
        let newGoalID = UUID().uuidString
        let newGoal = Goal(
            id: newGoalID,
            name: name,
            due: due,
            goalDescription: description,
            needsSync: true
        )
        modelContext.insert(newGoal)
        self.goals.append(newGoal)
        self.goals.sort { $0.due < $1.due }
        print("Created goal locally (needs sync): \(newGoal.name)")
        Task { await syncGoalToCloud(newGoal) }
    }

    func updateGoal(
        goal: Goal,
        name: String,
        due: Date,
        description: String?
    ) {
        goal.name = name
        goal.due = due
        goal.goalDescription = description
        goal.needsSync = true
        self.goals.sort { $0.due < $1.due }
        print("Updated goal locally (needs sync): \(goal.name)")
        Task { await syncGoalToCloud(goal) }
    }

    func deleteGoal(goal: Goal) {
        guard let modelContext = modelContext else { return }
        let goalIDToDelete = goal.id
        print(
            "Deleting goal locally and marking for cloud deletion: \(goal.name)"
        )

        // delete from UI n local
        self.goals.removeAll { $0.id == goalIDToDelete }
        modelContext.delete(goal)

        // delete from cloud
        addPendingDeletionID(goalIDToDelete, forKey: pendingGoalDeletionIDsKey)

        // sync cloud if online
        if networkMonitor.isConnected {
            Task { await syncPendingDeletions() }
        }
    }

    // crud task
    func fetchAllTasks() {
        guard let modelContext = modelContext, isSignedInToiCloud,
            networkMonitor.isConnected
        else {
            print("Skipping fetchTasks: Not signed in, no context, or offline.")
            return
        }
        let goalIds = goals.map { $0.id }
        guard !goalIds.isEmpty else {
            // no goal = delete all pending task
            let predicate = #Predicate<GoalTask> { !$0.needsSync }
            try? modelContext.delete(model: GoalTask.self, where: predicate)
            self.tasks = []
            print("No goals found, cleared non-pending local tasks.")
            return
        }

        let predicate = NSPredicate(format: "goal_id IN %@", goalIds)
        let query = CKQuery(recordType: "Tasks", predicate: predicate)

        database.fetch(withQuery: query, inZoneWith: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let queryResult):
                    let ckRecords = queryResult.matchResults.compactMap {
                        _,
                        recordResult in try? recordResult.get()
                    }
                    let cloudRecordIDs = Set(
                        ckRecords.map { $0.recordID.recordName }
                    )
                    var syncedTasks: [GoalTask] = []

                    // sync cloud
                    for record in ckRecords {
                        let goalId = record["goal_id"] as? String ?? ""

                        let parentGoal = self.goals.first { $0.id == goalId }

                        if let parentGoal = parentGoal {
                            let ckTask = GoalTask(
                                record: record,
                                goal: parentGoal
                            )
                            let taskID = ckTask.id
                            let predicate = #Predicate<GoalTask> {
                                $0.id == taskID
                            }

                            if let existingTask =
                                (try? modelContext.fetch(
                                    FetchDescriptor(predicate: predicate)
                                )).flatMap({ $0.first })
                            {
                                // Update
                                existingTask.name = ckTask.name
                                existingTask.workingTime = ckTask.workingTime
                                existingTask.focusDuration =
                                    ckTask.focusDuration
                                existingTask.isCompleted = ckTask.isCompleted
                                existingTask.goal = parentGoal
                                existingTask.needsSync = false
                                syncedTasks.append(existingTask)
                            } else {
                                // Insert
                                modelContext.insert(ckTask)
                                syncedTasks.append(ckTask)
                            }
                        } else {
                            print(
                                "Skipping task \(record.recordID.recordName) because parent goal \(goalId) not found locally."
                            )
                        }
                    }

                    // delete local task yang gaada di cloud
                    let localTasksToDelete = self.tasks.filter {
                        !cloudRecordIDs.contains($0.id) && !$0.needsSync
                    }
                    for taskToDelete in localTasksToDelete {
                        print(
                            "Deleting local task not found in Cloud: \(taskToDelete.name)"
                        )
                        modelContext.delete(taskToDelete)
                    }

                    // reload task from local
                    self.tasks =
                        (try? modelContext.fetch(FetchDescriptor<GoalTask>()))
                        ?? []

                case .failure(let error):
                    self.error =
                        "Failed to fetch tasks: \(error.localizedDescription)"
                }
            }
        }
    }

    func createTask(
        goalId: String,
        name: String,
        workingTime: Date,
        focusDuration: Int
    ) {
        guard let modelContext = modelContext,
            let parentGoal = self.goals.first(where: { $0.id == goalId })
        else { return }
        let newTaskID = UUID().uuidString
        let newTask = GoalTask(
            id: newTaskID,
            name: name,
            workingTime: workingTime,
            focusDuration: focusDuration,
            isCompleted: false,
            goal: parentGoal,
            needsSync: true
        )
        modelContext.insert(newTask)
        self.tasks.append(newTask)
        print("Created task locally (needs sync): \(newTask.name)")
        Task { await syncTaskToCloud(newTask) }
    }

    func updateTask(
        task: GoalTask,
        name: String,
        workingTime: Date,
        focusDuration: Int,
        isCompleted: Bool
    ) {
        task.name = name
        task.workingTime = workingTime
        task.focusDuration = focusDuration
        task.isCompleted = isCompleted
        task.needsSync = true
        print("Updated task locally (needs sync): \(task.name)")
        Task { await syncTaskToCloud(task) }
    }

    func deleteTask(task: GoalTask) {
        guard let modelContext = modelContext else { return }
        let taskIDToDelete = task.id
        print(
            "Deleting task locally and marking for cloud deletion: \(task.name)"
        )

        // delete from UI n local
        self.tasks.removeAll { $0.id == taskIDToDelete }
        modelContext.delete(task)

        // delete from cloud
        addPendingDeletionID(taskIDToDelete, forKey: pendingTaskDeletionIDsKey)

        // sync cloud if online
        if networkMonitor.isConnected {
            Task { await syncPendingDeletions() }
        }
    }

    // done task
    func toggleTaskCompletion(task: GoalTask) {
        updateTask(
            task: task,
            name: task.name,
            workingTime: task.workingTime,
            focusDuration: task.focusDuration,
            isCompleted: !task.isCompleted
        )
    }

    func getTasksForGoal(_ goalId: String) -> [GoalTask] {
        return tasks.filter { $0.goal?.id == goalId }
    }
}
