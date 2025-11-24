//
//  SplashScreenView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackground()

                VStack(spacing: geometry.size.height * 0.03) {
                    // logo
                    Image("finley")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * 0.3
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)

                    // app name
                    Text("Finline")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(opacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
