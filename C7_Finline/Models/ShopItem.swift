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
    case dogo
    case ebet
    //    case leo

    var price: Int {
        switch self {
        case .finley: return 0  // Free default character
        case .dogo: return 100
        case .ebet: return 50
        //        case .leo: return 125
        }
    }

    var displayName: String {
        switch self {
        case .finley: return "Finley"
        case .dogo: return "Dogo"
        case .ebet: return "Ebet"
        //        case .leo: return "leo"
        }
    }

    var imageName: String {
        switch self {
        case .finley: return "finley"
        case .dogo: return "dogo"
        case .ebet: return "ebet"
        //        case .leo: return "leo"
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
        case .dogo:
            return "FishingAnimatedScarf"
        case .ebet:
            return "FishingAnimatedGlasses"
        }
    }
    
    var restAnimationName: String {
        switch self {
        case .finley:
            return "SleepingAnimated"
        case .dogo:
            return "SleepingAnimatedScarf"
        case .ebet:
            return "SleepingAnimatedGlasses"
        }
        
    }
}
