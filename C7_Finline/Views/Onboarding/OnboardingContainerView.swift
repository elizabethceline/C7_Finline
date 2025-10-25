//
//  OnboardingContainerView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool
    
    init(hasCompletedOnboarding: Binding<Bool>, networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
        self._viewModel = StateObject(wrappedValue: OnboardingViewModel(networkMonitor: networkMonitor))
    }
    
    var body: some View {
        OnboardingView(
            viewModel: viewModel,
            hasCompletedOnboarding: $hasCompletedOnboarding
        )
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

#Preview {
    OnboardingContainerView(hasCompletedOnboarding: .constant(false))
}
