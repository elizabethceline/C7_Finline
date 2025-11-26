//
//  OnboardingView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep: OnboardingStep = .carousel

    enum OnboardingStep {
        case carousel
        case characterIntro
        case setProductiveHours
    }

    var body: some View {
        ZStack {
            switch currentStep {
            case .carousel:
                CarouselView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentStep = .characterIntro
                    }
                })

            case .characterIntro:
                CharacterIntroView(
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            currentStep = .setProductiveHours
                        }
                    },
                    username: $viewModel.username
                )

            case .setProductiveHours:
                SetProductiveHoursView(
                    productiveHours: $viewModel.productiveHours,
                    onComplete: {
                        Task {
                            await viewModel.saveUserProfile(
                                username: viewModel.username,
                                productiveHours: viewModel.productiveHours,
                                points: viewModel.points
                            )

                            await MainActor.run {
                                UserDefaults.standard.set(
                                    true,
                                    forKey: "hasCompletedOnboarding"
                                )

                                withAnimation(.easeInOut(duration: 0.6)) {
                                    hasCompletedOnboarding = true
                                }
                            }
                        }
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.6), value: currentStep)
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(),
        hasCompletedOnboarding: .constant(false)
    )
}
