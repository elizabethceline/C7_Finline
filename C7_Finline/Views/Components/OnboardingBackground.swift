//
//  OnboardingBackground.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 01/11/25.
//

import SwiftUI

struct OnboardingBackground: View {
    var body: some View {
        //        LinearGradient(
        //            colors: [
        //                Color(uiColor: .systemGray6),
        //                Color.primary.opacity(0.25),
        //            ],
        //            startPoint: .top,
        //            endPoint: .bottom
        //        )
        Rectangle()
            .fill(
                Color(uiColor: .systemGray6)
            )
            .ignoresSafeArea()
    }
}

#Preview {
    OnboardingBackground()
}
