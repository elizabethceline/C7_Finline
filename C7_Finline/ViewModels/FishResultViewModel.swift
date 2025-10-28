import SwiftData
import Foundation
import Combine

@MainActor
class FishResultViewModel: ObservableObject {
    @Published var currentResult: FishingResult?
    @Published var history: [FishingResult] = []
    @Published var bonusPoints: Int = 0
    @Published var userProfile: UserProfile?
    
    var fishCaught: [Fish] {
        currentResult?.caughtFish ?? []
    }
    
    var totalPoints: Int{
        fishCaught.reduce(0) { $0 + $1.points }
    }
    
    var grandTotal: Int{
        totalPoints + bonusPoints
    }
    private var context: ModelContext?
    private var profileManager: UserProfileManager?
    
    init(context: ModelContext? = nil, profileManager: UserProfileManager? = nil) {
        self.context = context
        self.profileManager = profileManager
        
        if context != nil {
            loadUserProfile()
            loadHistory()
        } else {
            history = []
        }
    }
    private func loadUserProfile() {
        guard let context else { return }
        let descriptor = FetchDescriptor<UserProfile>()
        userProfile = try? context.fetch(descriptor).first
    }
    
    
    func setProfileManager(_ manager: UserProfileManager) {
        self.profileManager = manager
    }
    
    func recordResult(from session: FocusSessionViewModel) {
        guard let context else {
            print("Skipping save — no SwiftData context (likely running in preview).")
            return
        }
        
        let result = FishingResult(caughtFish: session.fishingVM.caughtFish)
        context.insert(result)
        try? context.save()
        currentResult = result
        history.append(result)
    }
    
    func loadHistory() {
        guard let context else {
            history = []
            return
        }
        
        let descriptor = FetchDescriptor<FishingResult>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        history = (try? context.fetch(descriptor)) ?? []
    }
    
    
    //    func recordCombinedResult(fish: [Fish]) {
    //        guard let context else {
    //            print("Skipping save — no SwiftData context (likely running in preview).")
    //            self.currentResult = FishingResult(caughtFish: fish)
    //            return
    //        }
    //
    //        let result = FishingResult(caughtFish: fish)
    //        context.insert(result)
    //        try? context.save()
    //        currentResult = result
    //        history.append(result)
    //    }
    
    func recordCombinedResult(fish: [Fish], bonusPoints: Int) {
        let result = FishingResult(caughtFish: fish)
        self.currentResult = result
        self.bonusPoints = bonusPoints
        let fishPoints = self.totalPoints
        
        Task {
            await addPointsToProfile(fishPoints: fishPoints, bonusPoints: bonusPoints)
        }
        // Save to SwiftData
        guard let context else {
            print("Skipping save — no SwiftData context (likely running in preview).")
            return
        }
        
        context.insert(result)
        try? context.save()
        history.append(result)
    }
    
    private func addPointsToProfile(fishPoints: Int, bonusPoints: Int) async {
        guard let context else {
            print("No context, cannot add points to profile.")
            return
        }
        
        let totalToAdd = fishPoints + bonusPoints
        if totalToAdd == 0 { return }
        
        do {
            if userProfile == nil {
                let descriptor = FetchDescriptor<UserProfile>()
                userProfile = try context.fetch(descriptor).first
            }
            
            guard let profile = userProfile else {
                print("No user profile found to update points.")
                return
            }
            
            profile.points += totalToAdd
            profile.needsSync = true
            try context.save()
            
            print("Added \(totalToAdd) points to profile. New total: \(profile.points)")
            
            // Try syncing to CloudKit
            if let manager = profileManager {
                do {
                    try await manager.saveProfile(profile)
                    print("Synced points to CloudKit.")
                } catch {
                    print("Offline — will sync later: \(error.localizedDescription)")
                }
            } else {
                print("No UserProfileManager provided — local only.")
            }
            
        } catch {
            print("Error updating user profile: \(error)")
        }
    }
}
