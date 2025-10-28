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

    @State private var showSplash = true

    init(
        hasCompletedOnboarding: Binding<Bool>,
        networkMonitor: NetworkMonitor = NetworkMonitor()
    ) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
        self._viewModel = StateObject(
            wrappedValue: OnboardingViewModel(networkMonitor: networkMonitor)
        )
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                OnboardingView(
                    viewModel: viewModel,
                    hasCompletedOnboarding: $hasCompletedOnboarding
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            startSplashSequence()
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
    }

    private func startSplashSequence() {
        Task {
            // wait 2 sec
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // cek loading
            while viewModel.isLoading {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            await MainActor.run {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    OnboardingContainerView(hasCompletedOnboarding: .constant(false))
}
