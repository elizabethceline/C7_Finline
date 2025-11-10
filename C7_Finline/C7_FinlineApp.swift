//
//  C7_FinlineApp.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 21/10/25.
//

import SwiftData
import SwiftUI

@main
struct C7_FinlineApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var focusVM = FocusSessionViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var syncManager = BackgroundSyncManager.shared

    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Goal.self,
            GoalTask.self,
            PurchasedItem.self,
            FocusSessionResult.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(focusVM)
                .environmentObject(networkMonitor)
                .environmentObject(syncManager)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }

    private func handleScenePhaseChange(
        oldPhase: ScenePhase,
        newPhase: ScenePhase
    ) {
        switch newPhase {
        case .active:
            print("App became active")

        case .inactive:
            print("App became inactive")

        case .background:
            print("App entered background")

        @unknown default:
            break
        }
    }
}
