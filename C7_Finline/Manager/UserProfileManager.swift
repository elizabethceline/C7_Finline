//
//  UserProfileManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 24/10/25.
//

import CloudKit
import Foundation
import SwiftData

class UserProfileManager {
    private let cloudKit = CloudKitManager.shared
    private let networkMonitor: NetworkMonitor

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }

    func fetchProfile(
        userRecordID: CKRecord.ID,
        modelContext: ModelContext
    ) async throws -> UserProfile {
        let recordID = CKRecord.ID(
            recordName: "UserProfile_\(userRecordID.recordName)"
        )
        let targetUserID = userRecordID.recordName

        // Check local first
        let profilePredicate = #Predicate<UserProfile> { $0.id == targetUserID }
        let localProfile = try? modelContext.fetch(
            FetchDescriptor(predicate: profilePredicate)
        ).first

        do {
            // Fetch from CloudKit
            let record = try await cloudKit.fetchRecord(recordID: recordID)
            let ckProfile = UserProfile(record: record)

            if let existingProfile = localProfile {
                // Update existing
                existingProfile.username = ckProfile.username
                existingProfile.points = ckProfile.points
                existingProfile.productiveHoursJSON =
                    ckProfile.productiveHoursJSON
                existingProfile.bestFocusTime = ckProfile.bestFocusTime
                existingProfile.needsSync = false
                return existingProfile
            } else {
                // Insert new
                modelContext.insert(ckProfile)
                return ckProfile
            }
        } catch let error as CKError where error.code == .unknownItem {
            // Profile doesn't exist in CloudKit
            if let existingProfile = localProfile {
                existingProfile.needsSync = true
                return existingProfile
            } else {
                // Create empty profile
                let emptyHours = DayOfWeek.allCases.map {
                    ProductiveHours(day: $0)
                }
                let newProfile = UserProfile(
                    id: targetUserID,
                    username: "",
                    points: 0,
                    productiveHours: emptyHours,
                    bestFocusTime: 0,
                    needsSync: true
                )
                modelContext.insert(newProfile)
                return newProfile
            }
        }
    }

    func saveProfile(_ profile: UserProfile) async throws {
        guard networkMonitor.isConnected else {
            profile.needsSync = true
            return
        }

        let recordID = CKRecord.ID(recordName: "UserProfile_\(profile.id)")

        let record: CKRecord
        do {
            record = try await cloudKit.fetchRecord(recordID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: "UserProfile", recordID: recordID)
        }

        let finalRecord = profile.toRecord(record)
        _ = try await cloudKit.saveRecord(finalRecord)

        profile.needsSync = false
    }

    func syncPendingProfiles(modelContext: ModelContext) async {
        guard networkMonitor.isConnected else { return }

        let profilePredicate = #Predicate<UserProfile> { $0.needsSync == true }
        guard
            let profilesToSync = try? modelContext.fetch(
                FetchDescriptor(predicate: profilePredicate)
            )
        else { return }

        for profile in profilesToSync {
            do {
                try await saveProfile(profile)
            } catch {
                print("Failed to sync profile: \(error.localizedDescription)")
            }
        }
    }
}
