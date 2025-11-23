//
//  ShopItem.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 04/11/25.
//

import Foundation
import SwiftUI

enum ShopItem: String, CaseIterable, Codable {
    case finley  // Default character
    case glasses
    case scarf

    var price: Int {
        switch self {
        case .finley: return 0  // Free default character
        case .glasses: return 100
        case .scarf: return 50
        }
    }

    var displayName: String {
        switch self {
        case .finley: return "Default"
        case .glasses: return "Glasses"
        case .scarf: return "Scarf"
        }
    }

    var imageName: String {
        switch self {
        case .finley: return "finley"
        case .glasses: return "finley_glasses"
        case .scarf: return "finley_scarf"
        }
    }

    var image: Image {
        Image(imageName)
    }

    var isDefault: Bool {
        return self == .finley
    }
}

extension ShopItem {
    var focusAnimationName: String {
        switch self {
        case .finley:
            return "FishingAnimated"
        case .scarf:
            return "FishingAnimatedScarf"
        case .glasses:
            return "FishingAnimatedGlasses"
        }
    }

    var restAnimationName: String {
        switch self {
        case .finley:
            return "SleepingAnimated"
        case .scarf:
            return "SleepingAnimatedScarf"
        case .glasses:
            return "SleepingAnimatedGlasses"
        }

    }
}
