//
//  Color.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 01/11/25.
//

import SwiftUI

extension Color {
    static let primary = Color(hex: "34A8D3")
    static let secondary = Color(hex: "DBF3FC")
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0
        
        if scanner.scanHexInt64(&hexNumber) {
            let r = Double((hexNumber & 0xFF0000) >> 16) / 255
            let g = Double((hexNumber & 0x00FF00) >> 8) / 255
            let b = Double(hexNumber & 0x0000FF) / 255
            
            self = Color(red: r, green: g, blue: b)
        } else {
            self = Color.clear
        }
    }
}
