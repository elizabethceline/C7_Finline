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

class CloudKitViewModel: ObservableObject {
    
    @Published var isSignedInToiCloud = false
    @Published var username: String = ""
    @Published var error: String = ""
    @Published var isLoaded = false
    
    private let recordType = "UserProfile"
    private let database = CKContainer.default().privateCloudDatabase
    
    init() {
        getiCloudStatus()
        fetchOrCreateUserProfile()
    }
    
    // check icloud account
    private func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, err in
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
    
    // fetch/create user profile
    func fetchOrCreateUserProfile() {
        // get unique record id for current user
        CKContainer.default().fetchUserRecordID { [weak self] userRecordID, error in
            guard let self = self,
                  let userRecordID = userRecordID,
                  error == nil else {
                DispatchQueue.main.async {
                    self?.error = "Failed to get user record ID: \(error?.localizedDescription ?? "")"
                    self?.isLoaded = true
                }
                return
            }
            
            // create unique record id for this user's profile
            let recordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
            
            // fetch existing profile
            self.database.fetch(withRecordID: recordID) { record, error in
                DispatchQueue.main.async {
                    if let record = record, let name = record["username"] as? String {
                        // ada existing recordnya
                        self.username = name
                        self.isLoaded = true
                    } else if let ckError = error as? CKError, ckError.code == .unknownItem {
                        // gaada, create new one
                        self.createEmptyUserProfile(recordID: recordID)
                    } else if let error = error {
                        self.error = "Fetch failed: \(error.localizedDescription)"
                        self.isLoaded = true
                    }
                }
            }
        }
    }
    
    // create new profile
    private func createEmptyUserProfile(recordID: CKRecord.ID) {
        let newRecord = CKRecord(recordType: recordType, recordID: recordID)
        newRecord["username"] = "" as CKRecordValue
        
        database.save(newRecord) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = "Create failed: \(error.localizedDescription)"
                }
                self.isLoaded = true
                self.username = ""
            }
        }
    }
    
    // update or save profile
    func saveUserProfile(name: String) {
        CKContainer.default().fetchUserRecordID { [weak self] userRecordID, error in
            guard let self = self,
                  let userRecordID = userRecordID,
                  error == nil else {
                DispatchQueue.main.async { self?.error = "Failed to get user record ID" }
                return
            }
            
            let recordID = CKRecord.ID(recordName: "UserProfile_\(userRecordID.recordName)")
            
            self.database.fetch(withRecordID: recordID) { record, _ in
                let recordToSave = record ?? CKRecord(recordType: self.recordType, recordID: recordID)
                recordToSave["username"] = name as CKRecordValue
                
                self.database.save(recordToSave) { _, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.error = "Failed to save: \(error.localizedDescription)"
                        } else {
                            self.username = name
                        }
                    }
                }
            }
        }
    }
}

struct TestCloud: View {
    @StateObject private var vm = CloudKitViewModel()
    @State private var showingNamePrompt = false
    @State private var tempName = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("iCloud Signed In: \(vm.isSignedInToiCloud.description.uppercased())")
            Text("Username: \(vm.username.isEmpty ? "Not Set" : vm.username)")
                .font(.title3)
                .bold()
            
            if !vm.error.isEmpty {
                Text("Error: \(vm.error)").foregroundColor(.red)
            }
            
            Button("Change Name") {
                tempName = vm.username
                showingNamePrompt = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onChange(of: vm.isLoaded) { oldValue, newValue in
            if newValue && vm.username.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingNamePrompt = true
                }
            }
        }
        .alert("Enter Your Name", isPresented: $showingNamePrompt) {
            TextField("Your name", text: $tempName)
            Button("Save") {
                let cleanName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanName.isEmpty {
                    vm.saveUserProfile(name: cleanName)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This name will be synced with your iCloud account.")
        }
    }
}

#Preview {
    TestCloud()
}
