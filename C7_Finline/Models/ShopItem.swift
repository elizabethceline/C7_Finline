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
    case ebet
    
    var price: Int {
        switch self {
        case .dogo: return 100
        case .ebet: return 50
        }
    }
    
    var displayName: String {
        switch self {
        case .dogo: return "Dogo"
        case .ebet: return "Ebet"
        }
    }
    
    var imageName: String {
        switch self {
        case .dogo: return "dogo"
        case .ebet: return "ebet"
        }
    }
    
    var image: Image {
        Image(imageName)
    }
}


