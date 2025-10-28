//
//  OnboardingView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 24/10/25.
//

import SwiftUI

struct RootView: View {
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TestCloud()
            } else {
                OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}

#Preview {
    RootView()
}
