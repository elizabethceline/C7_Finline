import Foundation
import SwiftData
import SwiftUI
import Combine

#if os(iOS)
import ManagedSettings
//import FamilyControls
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class FocusSessionViewModel: ObservableObject {
    // Focus Session
    @Published var isFocusing = false
    @Published var remainingTime: TimeInterval = 0
    @Published var sessionDuration: TimeInterval = 30 * 60
    @Published var shouldReturnToStart = false
    @Published var taskTitle: String = ""
    @Published var goalName: String?
    @Published var errorMessage: String?
    
    // Rest Mode
    @Published var isResting: Bool = false
    @Published var totalRestSeconds: TimeInterval = 0
    @Published var restAllowanceSeconds: TimeInterval = 0
    @Published var restRemainingTime: TimeInterval = 0
    
    var earnedRestMinutes: Int {
        let restSeconds = (sessionDuration / (30 * 60)) * (5 * 60)
        return Int(restSeconds / 60)
    }
    
    var canRest: Bool {
        remainingRestSeconds >= 300
    }
    
    var remainingRestSeconds: TimeInterval {
        max(0, restAllowanceSeconds - totalRestSeconds)
    }
    
    // Nudge
    @Published var nudgeMeEnabled: Bool = true
    @Published var isShowingNudgeAlert: Bool = false
    var bonusPointsFromNudge: Int = 0
    
    private var nudgesTriggered = Set<Int>()
    private var isContinuingSession = false
    
    // Dependencies
    let fishingVM: FishingViewModel
    var authManager: FocusAuthorizationManager
    
    private(set) var goal: Goal?
    private(set) var task: GoalTask?
    
    // Private properties
    private var timer: Timer?
    private var restTimer: Timer?
    private var lastTickDate: Date?
    private var currentRestStart: Date?
    
    init(
        goal: Goal? = nil,
        task: GoalTask? = nil,
        fishingVM: FishingViewModel = FishingViewModel(),
        authManager: FocusAuthorizationManager = FocusAuthorizationManager()
    ) {
        self.goal = goal
        self.task = task
        self.fishingVM = fishingVM
        self.authManager = authManager
        
        if let task = task {
            self.goalName = goal?.name
            self.taskTitle = task.name
            self.sessionDuration = TimeInterval(task.focusDuration * 60)
            self.remainingTime = self.sessionDuration
        }
    }
    
    // Focus Session
    func startSession() {
        guard !isFocusing else {
            errorMessage = "Session is already in progress."
            return
        }
        
        isFocusing = true
        remainingTime = sessionDuration
        lastTickDate = Date()
        shouldReturnToStart = false
        bonusPointsFromNudge = 0
        
        isResting = false
        totalRestSeconds = 0
        let fullBlocks = floor(sessionDuration / (30 * 60))
        restAllowanceSeconds = fullBlocks * (5 * 60)
        currentRestStart = nil
        
        nudgesTriggered.removeAll()
        isShowingNudgeAlert = false
        
        if authManager.isEnabled && authManager.isAuthorized {
            authManager.applyShield()
        }
        
        Task {
                if authManager.isEnabled {
                    if !authManager.isAuthorized {
                        print("Deep Focus is ON but not authorized. Requesting authorization...")
                        await authManager.requestAuthorization()
                    }
                    
                    if authManager.isAuthorized {
                        authManager.applyShield()
                        print(" Deep Focus shield applied successfully.")
                    } else {
                        print("Deep Focus not applied — user denied or authorization failed.")
                    }
                }
                
                await fishingVM.startFishing(
                    for: sessionDuration,
                    deepFocusEnabled: authManager.isEnabled
                )
            }
        
        startTimer()
    }
    
    func endSession() async {
        guard isFocusing else { return }
        
        timer?.invalidate()
        timer = nil
        isFocusing = false
        isContinuingSession = false
        
        fishingVM.stopFishing()
        authManager.clearShield()
        
        if let task = task {
            task.isCompleted = true
        }
        
        shouldReturnToStart = true
    }
    
    func giveUp() async {
        guard isFocusing else { return }
        
        timer?.invalidate()
        timer = nil
        
        fishingVM.stopFishing()
        authManager.clearShield()
        
        isFocusing = false
        shouldReturnToStart = true
    }
    
    func addMoreTime(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) async {
        let extraTime = TimeInterval((hours * 3600) + (minutes * 60) + seconds)
        
        isContinuingSession = true
        
        self.remainingTime += extraTime
        self.sessionDuration += extraTime
        self.shouldReturnToStart = false
        self.isFocusing = true
        
        self.nudgeMeEnabled = false
        self.isShowingNudgeAlert = false
        self.nudgesTriggered.removeAll()
        
        if authManager.isEnabled {
            authManager.applyShield()
        }
        
        Task {
            await fishingVM.startFishing(
                for: extraTime,
                deepFocusEnabled: authManager.isEnabled,
                resume: true
            )
        }
        
        if timer == nil {
            startTimer()
        }
    }
    
    // Timer
    private func startTimer(isResuming: Bool = false) {
        if !isResuming {
            nudgesTriggered.removeAll()
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.remainingTime > 1 {
                    self.remainingTime -= 1
                    self.lastTickDate = Date()
                    self.checkNudgeAlerts()
                } else {
                    self.remainingTime = 0
                    await self.endSession()
                }
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    // Rest
    func startRest(for seconds: TimeInterval) {
        guard !isResting, seconds > 0, seconds <= remainingRestSeconds else { return }
        
        isResting = true
        currentRestStart = Date()
        totalRestSeconds += seconds
        restRemainingTime = seconds
        
        pauseSession()
        startRestTimer()
    }
    
    func endRest() {
        guard isResting else { return }
        
        currentRestStart = nil
        isResting = false
        stopRestTimer()
        resumeSession()
    }
    
    private func pauseSession() {
        guard isFocusing else { return }
        
        timer?.invalidate()
        timer = nil
        isFocusing = false
        
        fishingVM.pauseFishing()
        authManager.clearShield()
    }
    
    private func resumeSession() {
        guard !isFocusing, remainingTime > 0 else { return }
        
        isFocusing = true
        lastTickDate = Date()
        startTimer(isResuming: true)
        isResting = false
        
        fishingVM.resumeFishing()
        
        if authManager.isEnabled && authManager.isAuthorized {
            authManager.applyShield()
        }
    }
    
    private func startRestTimer() {
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.restRemainingTime > 0 {
                    self.restRemainingTime -= 1
                } else {
                    self.endRest()
                }
            }
        }
        RunLoop.current.add(restTimer!, forMode: .common)
    }

    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
    }
    
    // Nudge
    private func checkNudgeAlerts() {
        guard nudgeMeEnabled, !isContinuingSession else { return }
        
        let totalSeconds = sessionDuration
        var maxNudges = 0
        
        switch totalSeconds {
        case 0..<5*60:
            maxNudges = 0
        case 5*60..<30*60:
            maxNudges = 1
        case 30*60..<2*60*60:
            maxNudges = 2
        default:
            maxNudges = 3
        }
        
        guard maxNudges > 0 else { return }
        
        let interval = totalSeconds / Double(maxNudges + 1)
        
        for i in 1...maxNudges {
            let triggerTime = totalSeconds - interval * Double(i)
            if !nudgesTriggered.contains(i) && remainingTime <= triggerTime {
                isShowingNudgeAlert = true
                nudgesTriggered.insert(i)
            }
        }
    }
    
    func userConfirmedNudge() {
        isShowingNudgeAlert = false
        bonusPointsFromNudge += 20
    }
    
    // Reset
    func resetSession() {
        timer?.invalidate()
        timer = nil
        restTimer?.invalidate()
        restTimer = nil
        
        isFocusing = false
        isResting = false
        shouldReturnToStart = false
        remainingTime = 0
        taskTitle = ""
        
        isShowingNudgeAlert = false
        bonusPointsFromNudge = 0
        nudgesTriggered.removeAll()
    }
    
    // Result
    @MainActor
    func createResult(using context: ModelContext) -> FocusResultViewModel {
        let resultVM = FocusResultViewModel(
            context: context,
            networkMonitor: NetworkMonitor()
        )
        
        resultVM.recordSessionResult(
            fish: fishingVM.caughtFish,
            bonusPoints: bonusPointsFromNudge,
            duration: sessionDuration,
            task: task
        )
        
        return resultVM
    }
}
