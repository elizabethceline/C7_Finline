//
//  ShopItem.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 04/11/25.
//

import SwiftUI
import Foundation

enum ShopItem: String, CaseIterable, Codable {
    case dogo
    case pinguin
    case ebet

    var price: Int {
        switch self {
        case .dogo: return 100
        case .pinguin: return 150
        case .ebet: return 50
        }
    }

    var displayName: String {
        switch self {
        case .dogo: return "Dogo"
        case .pinguin: return "Pinguin"
        case .ebet: return "Ebet"
        }
    }

    var imageName: String {
        switch self {
        case .dogo: return "dogo"
        case .pinguin: return "pinguin"
        case .ebet: return "ebet"
        }
    }

    var image: Image {
        Image(imageName)
    }
}


