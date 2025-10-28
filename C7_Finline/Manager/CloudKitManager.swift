//
//  CloudKitManager.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 23/10/25.
//

import CloudKit
import Combine
import Foundation

class CloudKitManager {
    static let shared = CloudKitManager()

    let database = CKContainer.default().privateCloudDatabase
    private(set) var isSignedInToiCloud = false

    private init() {
        checkiCloudStatus()
    }

    private func checkiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                self?.isSignedInToiCloud = (status == .available)
            }
        }
    }

    // fetch
    func fetchRecord(recordID: CKRecord.ID) async throws -> CKRecord {
        return try await database.record(for: recordID)
    }

    func fetchRecords(query: CKQuery) async throws -> [CKRecord] {
        let result = try await database.records(matching: query)
        return result.matchResults.compactMap { _, recordResult in
            try? recordResult.get()
        }
    }

    // save
    func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        return try await database.save(record)
    }

    func saveRecords(_ records: [CKRecord]) async throws -> [CKRecord] {
        var savedRecords: [CKRecord] = []
        for record in records {
            let saved = try await saveRecord(record)
            savedRecords.append(saved)
        }
        return savedRecords
    }

    // delete
    func deleteRecord(recordID: CKRecord.ID) async throws {
        _ = try await database.deleteRecord(withID: recordID)
    }

    func deleteRecords(recordIDs: [CKRecord.ID]) async throws {
        for recordID in recordIDs {
            try await deleteRecord(recordID: recordID)
        }
    }

    // fetch user record id
    func fetchUserRecordID() async throws -> CKRecord.ID {
        return try await withCheckedThrowingContinuation { continuation in
            CKContainer.default().fetchUserRecordID { recordID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let recordID = recordID {
                    continuation.resume(returning: recordID)
                } else {
                    continuation.resume(
                        throwing: NSError(domain: "CloudKit", code: -1)
                    )
                }
            }
        }
    }
}
