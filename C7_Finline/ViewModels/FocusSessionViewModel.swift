import Foundation
import SwiftData
import SwiftUI
import Combine
import ActivityKit

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
    @Published var isSessionEnded: Bool = false
    @Published var didTimeRunOut: Bool = false
    @Published var didFinishEarly: Bool = false
    
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
    private var endTime: Date?
    private var restEndTime: Date?
    
    // Live Activity
    @Published var activity: Activity<FocusActivityAttributes>?
    var displayRemainingTime: TimeInterval {
        isResting ? restRemainingTime : remainingTime
    }
    private var lastLiveActivityUpdate: Date?
//    private let liveActivityUpdateInterval: TimeInterval = 60.0
    private var liveActivityUpdateInterval: TimeInterval {
        if remainingTime <= 60 {
            return 5.0
        } else if remainingTime <= 300 {
            return 45.0
        } else if remainingTime <= 600 {
            return 60.0
        } else {
            return 60.0
        }
    }

    
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
        
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        NotificationCenter.default.addObserver(
              self,
              selector: #selector(appWillTerminate),
              name: UIApplication.willTerminateNotification,
              object: nil
          )
    }
    deinit {
            NotificationCenter.default.removeObserver(self)
        }
    
    // Focus Session
    func startSession() {
        guard !isFocusing else {
            errorMessage = "Session is already in progress."
            return
        }
        
        print("Starting session... Nudge Me Enabled: \(nudgeMeEnabled)")
        
        isFocusing = true
        remainingTime = sessionDuration
        lastTickDate = Date()
        shouldReturnToStart = false
        endTime = Date().addingTimeInterval(sessionDuration)
        didTimeRunOut = false
        isSessionEnded = false
        didFinishEarly = false
        bonusPointsFromNudge = 0
        errorMessage = nil
        
        isResting = false
        totalRestSeconds = 0
        let fullBlocks = floor(sessionDuration / (30 * 60))
        restAllowanceSeconds = fullBlocks * (5 * 60)
        currentRestStart = nil
        
        nudgesTriggered.removeAll()
        isShowingNudgeAlert = false
        
        lastLiveActivityUpdate = nil
        
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
        
        // Start Live Activity
        startLiveActivity()
        
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
        
        //shouldReturnToStart = true
        do {
            try await Task.sleep(nanoseconds: 200_000_000)
        } catch {
            print("Sleep was cancelled or failed: \(error)")
        }

        // End Live Activity
        await endLiveActivity()
        
        isSessionEnded = true
    }
    
    func giveUp() async {
        guard isFocusing else { return }
        
        timer?.invalidate()
        timer = nil
        
        fishingVM.stopFishing()
        authManager.clearShield()
        
        isFocusing = false
        shouldReturnToStart = true
        
        // End Live Activity
        await endLiveActivity()
    }
    
    func finishEarly() {
        didFinishEarly = true
    }

    func addMoreTime(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) async {
        let extraTime = TimeInterval((hours * 3600) + (minutes * 60) + seconds)
        
        isContinuingSession = true
        
        self.remainingTime += extraTime
        self.sessionDuration += extraTime
        self.endTime = Date().addingTimeInterval(self.remainingTime)
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
        
        // Update Live Activity
        lastLiveActivityUpdate = nil
        await updateLiveActivity()
    }
    
    // Timer
    private func startTimer(isResuming: Bool = false) {
        if !isResuming {
            nudgesTriggered.removeAll()
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let endTime = self.endTime else { return }

                let remaining = endTime.timeIntervalSinceNow
                if remaining > 0 {
                    self.remainingTime = remaining
                    self.checkNudgeAlerts()
                    
                    let now = Date()
                    let interval = self.liveActivityUpdateInterval
                    
                    if self.lastLiveActivityUpdate == nil ||
                        now.timeIntervalSince(self.lastLiveActivityUpdate!) >= interval {
                        await self.updateLiveActivity()
                        self.lastLiveActivityUpdate = now
                    }
                    
                    // Update Live Activity setiap detik
//                    await self.updateLiveActivity()
                    
                } else {
                    self.remainingTime = 0
                    self.endTime = nil
                    self.didTimeRunOut = true
                    await self.activity?.update(using:
                        FocusActivityAttributes.ContentState(
                            remainingTime: 0,
                            restRemainingTime: 0,
                            taskTitle: "Session Complete",
                            isResting: false,
                            endTime: nil,
                            isCompleted: true
                        )
                    )

                    self.timer?.invalidate()
                    self.timer = nil
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
        restEndTime = Date().addingTimeInterval(seconds)
        pauseSession()
        startRestTimer()
        lastLiveActivityUpdate = nil
        Task { await updateLiveActivity() }
    }
    
    func endRest() {
        guard isResting else { return }
        
        currentRestStart = nil
        isResting = false
        restRemainingTime = 0
        restEndTime = nil
        stopRestTimer()
        resumeSession()
        lastLiveActivityUpdate = nil
        Task { await updateLiveActivity() }
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
        endTime = Date().addingTimeInterval(remainingTime)
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
                
                if let restEndTime = self.restEndTime {
                    let remaining = restEndTime.timeIntervalSinceNow
                    
                    if remaining > 0 {
                        self.restRemainingTime = remaining
                        let now = Date()
                        let interval = self.liveActivityUpdateInterval
                        if self.lastLiveActivityUpdate == nil ||
                            now.timeIntervalSince(self.lastLiveActivityUpdate!) >= interval {
                            await self.updateLiveActivity()
                            self.lastLiveActivityUpdate = now
                        }
                    } else {
                        // Rest is over
                        self.restRemainingTime = 0
                        self.restEndTime = nil
                        await self.activity?.update(using:
                                                FocusActivityAttributes.ContentState(
                                                    remainingTime: self.remainingTime,
                                                    restRemainingTime: 0,
                                                    taskTitle: self.taskTitle,
                                                    isResting: true,
                                                    endTime: nil,  // ← No endTime when rest is over
                                                    isCompleted: false,
                                                    isRestOver: true
                                                )
                                            )
                        self.stopRestTimer()
                        self.lastLiveActivityUpdate = nil
//                        await self.updateLiveActivity()
                        HapticManager.shared.playSessionEndHaptic()
                    }
                }
            }
        }
        RunLoop.current.add(restTimer!, forMode: .common)
    }
    
    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restEndTime = nil
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
        isSessionEnded = false
        remainingTime = 0
        restRemainingTime = 0
        restEndTime = nil
        taskTitle = ""
        if activity != nil {
                Task { await endLiveActivity() }
            }
        
        isShowingNudgeAlert = false
        bonusPointsFromNudge = 0
        nudgesTriggered.removeAll()
        
        // End Live Activity
        Task { await endLiveActivity() }
    }
    
    // Set task
    func setTask(_ task: GoalTask, goal: Goal?) {
        self.task = task
        self.goal = goal
        self.goalName = goal?.name
        self.taskTitle = task.name
        self.sessionDuration = TimeInterval(task.focusDuration * 60)
        self.remainingTime = self.sessionDuration
    }
    
    // Result
    @MainActor
    func createResult(using context: ModelContext, didComplete: Bool? = nil) -> FocusResultViewModel {
        print("createResult called")
        print("didComplete parameter: \(String(describing: didComplete))")
        print("remainingTime: \(remainingTime)")
        print("Task: \(task?.name ?? "nil")")
        
        let resultVM = FocusResultViewModel(
            context: context,
            networkMonitor: NetworkMonitor()
        )
        
        let shouldMarkComplete = didComplete ?? (remainingTime <= 0)
        print("Final shouldMarkComplete: \(shouldMarkComplete)")
        
        resultVM.recordSessionResult(
            fish: fishingVM.caughtFish,
            bonusPoints: bonusPointsFromNudge,
            duration: sessionDuration,
            task: task,
            shouldMarkComplete: shouldMarkComplete
        )
        
        return resultVM
    }
    
    // Live Activity Management
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        let attributes = FocusActivityAttributes(goalName: goalName ?? "Focus Mode", totalDuration: sessionDuration)
        
        let content = ActivityContent(
            state: FocusActivityAttributes.ContentState(
                remainingTime: remainingTime,
                restRemainingTime: 0,
                taskTitle: taskTitle,
                isResting: false,
                endTime: endTime,
                isCompleted: false
            ),
            staleDate: nil
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            self.activity = activity
            print("Live Activity started successfully")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivity() async {
        guard let activity else { return }
        
        let isCompleted = (!isResting && remainingTime <= 0)
        let isRestOver = (isResting && restRemainingTime <= 0)
        
        let shouldShowEndTime: Date? = {
            if isCompleted || isRestOver {
                return nil  // Always nil when completed or rest is over
            }
            
            if isResting {
                // Only show restEndTime if it's still in the future
                if let restEndTime = restEndTime, restEndTime.timeIntervalSinceNow > 0 {
                    return restEndTime
                }
                return nil
            } else {
                // Only show endTime if it's still in the future
                if let endTime = endTime, endTime.timeIntervalSinceNow > 0 {
                    return endTime
                }
                return nil
            }
        }()
        
        let updatedState = FocusActivityAttributes.ContentState(
            remainingTime: max(0, remainingTime),
            restRemainingTime: max(0, restRemainingTime),
            taskTitle: isCompleted ? "Session Complete" : taskTitle,
            isResting: isResting,
            endTime: shouldShowEndTime,
            isCompleted: isCompleted,
            isRestOver: isRestOver
        )
        
        await activity.update(using: updatedState)
    }


    
    private func endLiveActivity() async {
        guard let activity else { return }
        
        await activity.end(dismissalPolicy: .immediate)
        self.activity = nil
        print("Live Activity ended")
    }
    
//    @objc private func appDidBecomeActive() {
//        guard let endTime else { return }
//        remainingTime = max(0, endTime.timeIntervalSinceNow)
//        Task { await updateLiveActivity() }
//    }
    @objc private func appDidBecomeActive() {
        // Update focus session time
        if let endTime = endTime, !isResting {
            remainingTime = max(0, endTime.timeIntervalSinceNow)
        }
        
        // ADDED: Update rest time
        if let restEndTime = restEndTime, isResting {
            let remaining = restEndTime.timeIntervalSinceNow
            if remaining > 0 {
                restRemainingTime = remaining
            } else {
                // Rest ended while app was in background
                restRemainingTime = 0
                self.restEndTime = nil
                stopRestTimer()
            }
        }
        
        Task { await updateLiveActivity() }
    }

    
    @objc private func appWillTerminate() {
            print("App will terminate - cleaning up resources")
            
            timer?.invalidate()
            timer = nil
            restTimer?.invalidate()
            restTimer = nil
            
            authManager.clearShield()
            
            fishingVM.stopFishing()
            
            if let activity = activity {
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    await activity.end(dismissalPolicy: .immediate)
                    self.activity = nil
                    print("Live Activity ended due to app termination")
                    semaphore.signal()
                }
                _ = semaphore.wait(timeout: .now() + 1.0)
            }
            
            // Reset state
            isFocusing = false
            isResting = false
            restEndTime = nil
        
        }

    //    private func updateLiveActivity() async {
    //        guard let activity else { return }
    //
    //        let updatedContent = ActivityContent(
    //            state: FocusActivityAttributes.ContentState(
    //                remainingTime: remainingTime,
    //                taskTitle: taskTitle,
    //                isResting: isResting
    //            ),
    //            staleDate: nil
    //        )
    //
    //        await activity.update(updatedContent)
    //    }
    //
    //    private func endLiveActivity() async {
    //        guard let activity else { return }
    //
    //        let finalContent = ActivityContent(
    //            state: FocusActivityAttributes.ContentState(
    //                remainingTime: 0,
    //                taskTitle: taskTitle,
    //                isResting: false
    //            ),
    //            staleDate: nil
    //        )
    //
    //        await activity.end(finalContent, dismissalPolicy: .immediate)
    //        self.activity = nil
    //        print("Live Activity ended")
    //    }
}
