//
//  GoalViewModel.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 28/10/25.
//

import SwiftUI
import FoundationModels
import Combine
import SwiftData

@MainActor
final class GoalViewModel: ObservableObject {
    private let goalManager: GoalManager
    private let networkMonitor: NetworkMonitor
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.goalManager = GoalManager(networkMonitor: networkMonitor)
    }
    
    func createGoal(name: String, deadline: Date, description: String?, modelContext: ModelContext) async -> Goal {
        return goalManager.createGoal(
            name: name,
            due: deadline,
            description: description,
            modelContext: modelContext
        )
    }
    
    func updateGoal(goal: Goal, name: String, deadline: Date, description: String?) {
        goalManager.updateGoal(
            goal: goal,
            name: name,
            due: deadline,
            description: description
        )
    }
    
}
