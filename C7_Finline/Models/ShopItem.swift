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
//    case leo
    
    var price: Int {
        switch self {
        case .dogo: return 100
        case .ebet: return 50
//        case .leo: return 125
        }
    }
    
    var displayName: String {
        switch self {
        case .dogo: return "Dogo"
        case .ebet: return "Ebet"
//        case .leo: return "leo"
        }
    }
    
    var imageName: String {
        switch self {
        case .dogo: return "dogo"
        case .ebet: return "ebet"
//        case .leo: return "leo"
        }
    }
    
    var image: Image {
        Image(imageName)
    }
}


