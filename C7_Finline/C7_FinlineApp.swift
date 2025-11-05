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
    @StateObject private var focusVM = FocusSessionViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Goal.self,
            GoalTask.self,
            PurchasedItem.self,
            FocusSessionResult.self
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
        }
        .modelContainer(sharedModelContainer)
    }
}
