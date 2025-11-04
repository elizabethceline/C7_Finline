//
//  OnboardingCard.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftUI

struct OnboardingCardView: View {
    let card: OnboardingCard

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                Image(systemName: card.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .foregroundColor(.blue.opacity(0.7))
            )
    }
}

#Preview {
    OnboardingCardView(
        card: OnboardingCard(
            title: "Halo",
            description: "Halo 123",
            imageName: "star.fill"
        )
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
