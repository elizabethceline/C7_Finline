//
//  FocusResultViewModel.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 03/11/25.
//
import SwiftUI
import Foundation
import Combine
import SwiftData

@MainActor
class FocusResultViewModel: ObservableObject {
    @Published var currentResult: FocusSessionResult?
    @Published var history: [FocusSessionResult] = []
    @Published var bonusPoints: Int = 0
    @Published var userProfile: UserProfile?
    @Published var isSyncing: Bool = false
    @Published var syncError: String?
    
    var fishCaught: [Fish] {
        currentResult?.caughtFish ?? []
    }
    
    var totalFishPoints: Int {
        fishCaught.reduce(0) { $0 + $1.points }
    }
    
    var grandTotal: Int {
        totalFishPoints + bonusPoints
    }
    
    private var context: ModelContext?
    private let userProfileManager: UserProfileManager
    
    init(context: ModelContext? = nil, networkMonitor: NetworkMonitor) {
        self.context = context
        self.userProfileManager = UserProfileManager(networkMonitor: networkMonitor)
        
        if context != nil {
            loadUserProfile()
            loadHistory()
        }
    }

    
    private func loadUserProfile() {
        guard let context else { return }
        let descriptor = FetchDescriptor<UserProfile>()
        userProfile = try? context.fetch(descriptor).first
    }
    
    func loadHistory() {
        guard let context else {
            history = []
            return
        }
        
        let descriptor = FetchDescriptor<FocusSessionResult>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        history = (try? context.fetch(descriptor)) ?? []
    }
    
    func recordSessionResult(
        fish: [Fish],
        bonusPoints: Int,
        duration: TimeInterval,
        task: GoalTask?
    ) {
        self.bonusPoints = bonusPoints
        
        let result = FocusSessionResult(
            caughtFish: fish,
            duration: duration,
            task: task
        )
        self.currentResult = result
        
        Task {
            await saveResultAndUpdateProfile(result: result, bonusPoints: bonusPoints)
        }
    }
    
    private func saveResultAndUpdateProfile(
        result: FocusSessionResult,
        bonusPoints: Int
    ) async {
        guard let context else {
            print("No context — skipping save")
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            context.insert(result)
            
            if userProfile == nil {
                let descriptor = FetchDescriptor<UserProfile>()
                userProfile = try context.fetch(descriptor).first
            }
            
            guard let profile = userProfile else {
                print("No user profile found")
                try context.save()
                history.append(result)
                isSyncing = false
                return
            }
            
            let totalPoints = result.totalPoints + bonusPoints
            profile.points += totalPoints
            
            if result.duration > profile.bestFocusTime {
                profile.bestFocusTime = result.duration
                print("New best focus time: \(Int(result.duration / 60)) minutes!")
            }
            
            profile.needsSync = true
            
            try context.save()
            history.append(result)
            
            try await userProfileManager.saveProfile(profile)
            print("Synced to CloudKit: +\(totalPoints) points")
            
            isSyncing = false
            
        } catch {
            syncError = error.localizedDescription
            print("Error saving result: \(error)")
            isSyncing = false
        }
    }
}
