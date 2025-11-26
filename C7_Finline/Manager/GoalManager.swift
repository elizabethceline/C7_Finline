//
//  GoalManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 24/10/25.
//

import CloudKit
import Foundation
import SwiftData

class GoalManager {
    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor
    private let pendingDeletionKey = "pendingGoalDeletionIDs"

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }

    // crud goal
    func fetchGoals(modelContext: ModelContext) async throws -> [Goal] {
        guard networkMonitor.isConnected else {
            return try modelContext.fetch(
                FetchDescriptor<Goal>(sortBy: [
                    SortDescriptor(\.due, order: .forward)
                ])
            )
        }

        let query = CKQuery(
            recordType: "Goals",
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "due", ascending: true)]

        let ckRecords = try await cloudKit.fetchRecords(query: query)
        let cloudRecordIDs = Set(ckRecords.map { $0.recordID.recordName })

        // Sync from cloud
        for record in ckRecords {
            let ckGoal = Goal(record: record)
            let goalID = ckGoal.id
            let predicate = #Predicate<Goal> { $0.id == goalID }

            if let existingGoal = try? modelContext.fetch(
                FetchDescriptor(predicate: predicate)
            ).first {
                // Update existing
                existingGoal.name = ckGoal.name
                existingGoal.due = ckGoal.due
                existingGoal.goalDescription = ckGoal.goalDescription
                existingGoal.needsSync = false
            } else {
                // Insert new
                modelContext.insert(ckGoal)
            }
        }

        // Delete local goals not in cloud
        let allLocalGoals = try modelContext.fetch(FetchDescriptor<Goal>())
        let goalsToDelete = allLocalGoals.filter {
            !cloudRecordIDs.contains($0.id) && !$0.needsSync
        }

        for goal in goalsToDelete {
            modelContext.delete(goal)
        }

        try? modelContext.save()

        return try modelContext.fetch(
            FetchDescriptor<Goal>(sortBy: [
                SortDescriptor(\.due, order: .forward)
            ])
        )
    }

    func createGoal(
        name: String,
        due: Date,
        description: String?,
        modelContext: ModelContext
    ) -> Goal {
        let newGoalID = UUID().uuidString
        let newGoal = Goal(
            id: newGoalID,
            name: name,
            due: due,
            goalDescription: description,
            needsSync: true
        )
        modelContext.insert(newGoal)

        Task {
            await syncGoal(newGoal)
        }

        return newGoal
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

        Task {
            await syncGoal(goal)
        }
    }

    func deleteGoal(goal: Goal, modelContext: ModelContext) {
        let goalIDToDelete = goal.id

        modelContext.delete(goal)
        addPendingDeletionID(goalIDToDelete)

        if networkMonitor.isConnected {
            Task {
                await syncPendingDeletions()
            }
        }
    }

    func syncGoal(_ goal: Goal) async {
        guard networkMonitor.isConnected else {
            goal.needsSync = true
            return
        }

        // Skip if marked for deletion
        if getPendingDeletionIDs().contains(goal.id) {
            return
        }

        let recordID = CKRecord.ID(recordName: goal.id)

        do {
            let record: CKRecord
            do {
                record = try await cloudKit.fetchRecord(recordID: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                record = CKRecord(recordType: "Goals", recordID: recordID)
            }

            record["name"] = goal.name as CKRecordValue
            record["due"] = goal.due as CKRecordValue
            record["description"] = goal.goalDescription as CKRecordValue?

            _ = try await cloudKit.saveRecord(record)

            await MainActor.run {
                goal.needsSync = false
            }
        } catch {
            print(
                "Failed to sync goal '\(goal.name)': \(error.localizedDescription)"
            )
        }
    }

    func syncPendingGoals(modelContext: ModelContext) async {
        guard networkMonitor.isConnected else { return }

        let goalPredicate = #Predicate<Goal> { $0.needsSync == true }
        let pendingDeletionIDs = getPendingDeletionIDs()

        guard
            let goalsToSync = try? modelContext.fetch(
                FetchDescriptor(predicate: goalPredicate)
            )
        else { return }

        let filteredGoals = goalsToSync.filter {
            !pendingDeletionIDs.contains($0.id)
        }

        for goal in filteredGoals {
            await syncGoal(goal)
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
                    "Failed to delete goal \(id): \(error.localizedDescription)"
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
}
