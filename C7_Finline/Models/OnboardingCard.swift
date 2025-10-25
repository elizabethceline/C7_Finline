//
//  OnboardingCard.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import Foundation

struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}
