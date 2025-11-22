//
//  UIColor+Finline.swift
//  FinlineShieldConfig
//
//  Created by Gabriella Natasya Pingky Davis on 22/11/25.
//

import UIKit

extension UIColor {
    static let finlinePrimary = UIColor(hex: "34A8D3")
    static let finlineSecondary = UIColor(hex: "DBF3FC")
    static let finlineDarkGray = UIColor(hex: "424242")
    
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0
        
        if scanner.scanHexInt64(&hexNumber) {
            let r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
            let g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
            let b = CGFloat(hexNumber & 0x0000FF) / 255
            
            self.init(red: r, green: g, blue: b, alpha: 1.0)
        } else {
            self.init(white: 1.0, alpha: 0.0)
        }
    }
}
