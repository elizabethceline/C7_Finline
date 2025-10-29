import Foundation
import SwiftData
import SwiftUI
import Combine

#if os(iOS)
import ManagedSettings
import FamilyControls
import UIKit
#elseif os(macOS)
import AppKit
#endif

//@MainActor
final class FocusSessionViewModel: ObservableObject {
    @Published var isFocusing = false
    @Published var remainingTime: TimeInterval = 0
    @Published var sessionDuration: TimeInterval = 25 * 60
    @Published var deepFocusEnabled = true
    @Published var totalFocusedSeconds: TimeInterval = 0
    @Published var isAuthorized: Bool = false
    @Published var authorizationError: String?
    @Published var shouldReturnToStart = false
    @Published var taskTitle: String = ""
    @Published var nudgeMeEnabled: Bool = false
    @Published var isShowingNudgeAlert: Bool = false
    @Published var goalName: String?
    //@Published var taskDescription: String?
    private var nudgesTriggered = Set<Int>()
    
    private var hasNudgeBeenTriggered: Bool = false
    var bonusPointsFromNudge: Int = 0
    @Published var accumulatedFish: [Fish] = []

    #if os(iOS)
    @Published var selection = FamilyActivitySelection()
    private let managedStore = ManagedSettingsStore()
    #else
    @Published var selection = FamilyActivitySelectionFallback()
    #endif

    let fishingVM = FishingViewModel()
    let userProfileManager: UserProfileManager
    private let networkMonitor: NetworkMonitor
//    let fishResultVM: FishResultViewModel
//    private let userProfileManager: UserProfileManager?

    private var timer: Timer?
    private var lastTickDate: Date?
    private let selectionDefaultsKey = "FocusSelectionData"
    private var cancellables = Set<AnyCancellable>()

    #if os(macOS)
    struct FamilyActivitySelectionFallback: Codable, Equatable {
        var applicationTokens: Set<String> = []
        var webDomainTokens: Set<String> = []
    }
    #endif

//    init() {
//        loadSelection()
//        updateAuthorizationStatus()
//    }
//
    
    private(set) var goal: Goal?
       private(set) var task: GoalTask?

      
//    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
//        self.networkMonitor = networkMonitor
//        self.userProfileManager = UserProfileManager(networkMonitor: networkMonitor)
//        loadSelection()
//        updateAuthorizationStatus()
//    }
    
    init(goal: Goal? = nil, task: GoalTask? = nil, networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.goal = goal
        self.task = task
        self.networkMonitor = networkMonitor
        self.userProfileManager = UserProfileManager(networkMonitor: networkMonitor)

        loadSelection()
        updateAuthorizationStatus()

        if let goal = goal, let task = task {
            self.goalName = goal.name
            self.taskTitle = task.name
            self.sessionDuration = TimeInterval(task.focusDuration * 60)
            self.remainingTime = self.sessionDuration
        }
    }

//    init(userProfileManager: UserProfileManager? = nil) {
//           self.userProfileManager = userProfileManager
//           self.fishingVM = FishingViewModel(userProfileManager: userProfileManager)
//           loadSelection()
//           updateAuthorizationStatus()
//       }

    func startSession() {
        guard !isFocusing else { return }
        accumulatedFish.removeAll()
        shouldReturnToStart = false
        //hasNudgeBeenTriggered = false
        bonusPointsFromNudge = 0
        isFocusing = true
        remainingTime = sessionDuration
        lastTickDate = Date()
        
        nudgesTriggered.removeAll()
        isShowingNudgeAlert = false

        if deepFocusEnabled {
            if isAuthorized {
                applyShield()
            } else {
                configureAuthorizationIfNeeded()
                authorizationError = "Screen Time authorization required."
            }
        }

        Task {
            await fishingVM.startFishing(for: sessionDuration, deepFocusEnabled: deepFocusEnabled)
        }

        startTimer()
        print("nudge me: (\(nudgeMeEnabled))")
    }

    func endSession() async {
        guard isFocusing else { return }
        isFocusing = false
        task?.isCompleted = true

        timer?.invalidate()
        timer = nil

        bankCaughtFish()
        fishingVM.stopFishing()

        if deepFocusEnabled { clearShield() }

        if let last = lastTickDate {
            let delta = Date().timeIntervalSince(last)
            totalFocusedSeconds += min(sessionDuration, delta)
        }

        await MainActor.run {
            shouldReturnToStart = true
        }
    }



    private func startTimer() {
        nudgesTriggered.removeAll()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                if self.remainingTime > 1 {
                    self.remainingTime -= 1
                    self.lastTickDate = Date()
//                    let halfwayPoint = self.sessionDuration / 2
//                    if self.nudgeMeEnabled &&
//                        !self.hasNudgeBeenTriggered &&
//                        self.remainingTime <= halfwayPoint {
//
//                        self.isShowingNudgeAlert = true
//                        self.hasNudgeBeenTriggered = true
//                    }
                    self.checkNudgeAlerts()
                } else {
                    self.remainingTime = 0
                    await self.endSession()
                }
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func checkNudgeAlerts() {
        guard nudgeMeEnabled else { return }
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
                print("Nudge \(i) triggered at remaining time: \(remainingTime)")
            }
        }
    }
    
    private func bankCaughtFish(){
        self.accumulatedFish.append(contentsOf: fishingVM.caughtFish)
    }
    
    func addMoreTime(minutes: Int) async {
        let extraTime = TimeInterval(minutes * 60)

        bankCaughtFish()
        
        self.remainingTime = extraTime
        self.sessionDuration = extraTime
        self.shouldReturnToStart = false
        self.isFocusing = true
        self.hasNudgeBeenTriggered = true
        
        if deepFocusEnabled {
            applyShield()
        }
        
        Task {
            await fishingVM.startFishing(for: extraTime, deepFocusEnabled: deepFocusEnabled)
        }

        self.startTimer()
    }
    
    func stopSessionForEarlyFinish() async {
        guard isFocusing else { return }
        isFocusing = false

        timer?.invalidate()
        timer = nil

        bankCaughtFish()
        fishingVM.stopFishing()

        if deepFocusEnabled { clearShield() }
        
        if let last = lastTickDate {
            let delta = Date().timeIntervalSince(last)
            totalFocusedSeconds += min(sessionDuration, delta)
        }
    }
    
    func giveUp() async{
        guard isFocusing else { return }
        
        print("Session given up!")
        // Stop timer immediately
        timer?.invalidate()
        timer = nil
        
        fishingVM.stopFishing()
        if deepFocusEnabled { clearShield() }
        
        isFocusing = false
        shouldReturnToStart = true
    }
    
    func resetSession() {
        timer?.invalidate()
        timer = nil
        
        
        isFocusing = false
        shouldReturnToStart = false
        remainingTime = 0
        taskTitle = ""
        
        isShowingNudgeAlert = false
        hasNudgeBeenTriggered = false
        bonusPointsFromNudge = 0
        accumulatedFish.removeAll()
    }

    func userConfirmedNudge() {
        isShowingNudgeAlert = false
        self.bonusPointsFromNudge += 20
        print("User confirmed nudge, 20 points awarded.")
    }
    
    private func applyShield() {
        #if os(iOS)
        if selection.applicationTokens.isEmpty && selection.webDomainTokens.isEmpty {
            managedStore.shield.applicationCategories = .all()
            managedStore.shield.webDomainCategories = .all()
        } else {
            managedStore.shield.applications = selection.applicationTokens
            managedStore.shield.webDomains = selection.webDomainTokens
        }
        #endif
    }

    private func clearShield() {
        #if os(iOS)
        managedStore.shield.applications = nil
        managedStore.shield.webDomains = nil
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomainCategories = nil
        #endif
    }

    private func saveSelection() {
        do {
            let data = try JSONEncoder().encode(selection)
            UserDefaults.standard.set(data, forKey: selectionDefaultsKey)
        } catch {
            print("Failed to encode selection: \(error)")
        }
    }

    private func loadSelection() {
        guard let data = UserDefaults.standard.data(forKey: selectionDefaultsKey) else { return }
        #if os(iOS)
        if let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        }
        #else
        if let decoded = try? JSONDecoder().decode(FamilyActivitySelectionFallback.self, from: data) {
            selection = decoded
        }
        #endif
    }

    func configureAuthorizationIfNeeded() {
        #if os(iOS)
        Task { @MainActor in
            do {
                let center = AuthorizationCenter.shared
                switch center.authorizationStatus {
                case .notDetermined, .denied:
                    try await center.requestAuthorization(for: .individual)
                default:
                    break
                }
                updateAuthorizationStatus()
                if isAuthorized && isFocusing && deepFocusEnabled {
                    applyShield()
                }
            } catch {
                self.authorizationError = error.localizedDescription
                print("FamilyControls authorization error: \(error)")
            }
        }
        #else
        isAuthorized = false
        #endif
    }

    private func updateAuthorizationStatus() {
        #if os(iOS)
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = (status == .approved)
        if !isAuthorized {
            print("Screen Time access not yet granted.")
        }
        #else
        isAuthorized = false
        #endif
    }

    func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.ScreenTime-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(
                URL(fileURLWithPath: "/System/Applications/System Settings.app")
            )
        }
        #endif
    }
}

