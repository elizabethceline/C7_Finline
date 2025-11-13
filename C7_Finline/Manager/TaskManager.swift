//
//  TaskManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 24/10/25.
//

import CloudKit
import Foundation
import SwiftData

class TaskManager {
    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor
    private let pendingDeletionKey = "pendingTaskDeletionIDs"
    private let notificationManager = NotificationManager.shared

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }

    // crud task
    func fetchTasks(
        for goals: [Goal],
        modelContext: ModelContext
    ) async throws -> [GoalTask] {
        guard networkMonitor.isConnected else {
            return try modelContext.fetch(FetchDescriptor<GoalTask>())
        }

        let goalIds = goals.map { $0.id }
        guard !goalIds.isEmpty else {
            // No goals = delete all non-pending tasks
            let predicate = #Predicate<GoalTask> { !$0.needsSync }
            try? modelContext.delete(model: GoalTask.self, where: predicate)
            try? modelContext.save()
            return []
        }

        let predicate = NSPredicate(format: "goal_id IN %@", goalIds)
        let query = CKQuery(recordType: "Tasks", predicate: predicate)

        let ckRecords = try await cloudKit.fetchRecords(query: query)
        let cloudRecordIDs = Set(ckRecords.map { $0.recordID.recordName })

        // Sync from cloud
        for record in ckRecords {
            let goalId = record["goal_id"] as? String ?? ""
            guard let parentGoal = goals.first(where: { $0.id == goalId })
            else { continue }

            let ckTask = GoalTask(record: record, goal: parentGoal)
            let taskID = ckTask.id
            let taskPredicate = #Predicate<GoalTask> { $0.id == taskID }

            if let existingTask = try? modelContext.fetch(
                FetchDescriptor(predicate: taskPredicate)
            ).first {
                // Update existing
                existingTask.name = ckTask.name
                existingTask.workingTime = ckTask.workingTime
                existingTask.focusDuration = ckTask.focusDuration
                existingTask.isCompleted = ckTask.isCompleted
                existingTask.goal = parentGoal
                existingTask.needsSync = false
            } else {
                // Insert new
                modelContext.insert(ckTask)
            }
        }

        // Delete local tasks not in cloud
        let goalIdSet = Set(goalIds)
        let allLocalTasks = try modelContext.fetch(FetchDescriptor<GoalTask>())
        let tasksToDelete = allLocalTasks.filter { task in
            guard let taskGoalId = task.goal?.id, goalIdSet.contains(taskGoalId)
            else {
                return false
            }
            return !cloudRecordIDs.contains(task.id) && !task.needsSync
        }

        for task in tasksToDelete {
            modelContext.delete(task)
        }

        try? modelContext.save()

        return try modelContext.fetch(FetchDescriptor<GoalTask>())
    }

    func createTask(
        goal: Goal,
        name: String,
        workingTime: Date,
        focusDuration: Int,
        modelContext: ModelContext
    ) -> GoalTask {
        let newTask = GoalTask(
            id: UUID().uuidString,
            name: name,
            workingTime: workingTime,
            focusDuration: focusDuration,
            isCompleted: false,
            goal: goal,
            needsSync: true
        )
        modelContext.insert(newTask)

        Task {
            await syncTask(newTask)

            if let username = await fetchCurrentUsername() {
                await notificationManager.scheduleNotificationsForTasks(
                    [newTask],
                    username: username
                )
            }
        }

        return newTask
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

        Task {
            await syncTask(task)

            if let username = await fetchCurrentUsername() {
                if isCompleted {
                    // Remove notification if task is completed
                    notificationManager.removeNotification(for: task.id)
                } else {
                    // Remove old notification and schedule new one
                    notificationManager.removeNotification(for: task.id)
                    await notificationManager.scheduleNotificationsForTasks(
                        [task],
                        username: username
                    )
                }
            }
        }
    }

    func deleteTask(task: GoalTask, modelContext: ModelContext) {
        let taskIDToDelete = task.id

        // Remove notification
        notificationManager.removeNotification(for: taskIDToDelete)

        modelContext.delete(task)
        addPendingDeletionID(taskIDToDelete)

        if networkMonitor.isConnected {
            Task {
                await syncPendingDeletions()
            }
        }
    }

    // complete task
    func toggleTaskCompletion(task: GoalTask) {
        updateTask(
            task: task,
            name: task.name,
            workingTime: task.workingTime,
            focusDuration: task.focusDuration,
            isCompleted: !task.isCompleted
        )
    }

    func syncTask(_ task: GoalTask) async {
        guard networkMonitor.isConnected else {
            task.needsSync = true
            return
        }

        // Skip if marked for deletion
        if getPendingDeletionIDs().contains(task.id) {
            return
        }

        guard let goalID = task.goal?.id else {
            return
        }

        let recordID = CKRecord.ID(recordName: task.id)

        do {
            let record: CKRecord
            do {
                record = try await cloudKit.fetchRecord(recordID: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                record = CKRecord(recordType: "Tasks", recordID: recordID)
            }

            record["name"] = task.name as CKRecordValue
            record["working_time"] = task.workingTime as CKRecordValue
            record["focus_duration"] = task.focusDuration as CKRecordValue
            record["is_completed"] = (task.isCompleted ? 1 : 0) as CKRecordValue
            record["goal_id"] = goalID as CKRecordValue

            _ = try await cloudKit.saveRecord(record)

            await MainActor.run {
                task.needsSync = false
            }
        } catch {
            print(
                "Failed to sync task '\(task.name)': \(error.localizedDescription)"
            )
        }
    }

    func syncPendingTasks(modelContext: ModelContext) async {
        guard networkMonitor.isConnected else { return }

        let taskPredicate = #Predicate<GoalTask> { $0.needsSync == true }
        let pendingDeletionIDs = getPendingDeletionIDs()

        guard
            let tasksToSync = try? modelContext.fetch(
                FetchDescriptor(predicate: taskPredicate)
            )
        else { return }

        let filteredTasks = tasksToSync.filter {
            !pendingDeletionIDs.contains($0.id)
        }

        for task in filteredTasks {
            await syncTask(task)
        }
    }

    func syncPendingDeletions() async {
        guard networkMonitor.isConnected else { return }

        let idsToDelete = getPendingDeletionIDs()

        for id in idsToDelete {
            let recordID = CKRecord.ID(recordName: id)
            do {
                try await cloudKit.deleteRecord(recordID: recordID)
                removePendingDeletionID(id)
            } catch let error as CKError where error.code == .unknownItem {
                removePendingDeletionID(id)
            } catch {
                print(
                    "Failed to delete task \(id): \(error.localizedDescription)"
                )
            }
        }
    }

    private func getPendingDeletionIDs() -> Set<String> {
        let array =
            UserDefaults.standard.stringArray(forKey: pendingDeletionKey) ?? []
        return Set(array)
    }

    private func savePendingDeletionIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: pendingDeletionKey)
    }

    private func addPendingDeletionID(_ id: String) {
        var currentIDs = getPendingDeletionIDs()
        currentIDs.insert(id)
        savePendingDeletionIDs(currentIDs)
    }

    private func removePendingDeletionID(_ id: String) {
        var currentIDs = getPendingDeletionIDs()
        if currentIDs.remove(id) != nil {
            savePendingDeletionIDs(currentIDs)
        }
    }

    private func fetchCurrentUsername() async -> String? {
        do {
            let userRecordID = try await CKContainer.default().userRecordID()
            let profileRecordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
            let record = try await CloudKitManager.shared.fetchRecord(recordID: profileRecordID)
            return record["username"] as? String
        } catch {
            print("Failed to fetch current username: \(error.localizedDescription)")
            return nil
        }
    }
}
