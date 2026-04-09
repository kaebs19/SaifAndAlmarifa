//
//  Extension+Color.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Core/AppColors/Extension+Color.swift
//  Color extensions - Hex parsing & Adaptive (Light/Dark) support

import SwiftUI
import UIKit

// MARK: - Color + Hex
extension Color {

    /// إنشاء لون من Hex string
    /// - Parameter hex: قيمة Hex (3, 6, أو 8 أحرف) - مع أو بدون "#"
    /// - مثال: `Color(hex: "FFD700")` أو `Color(hex: "#FFD700")`
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// إنشاء لون يتكيف مع Light/Dark Mode من Hex strings
    /// - Parameters:
    ///   - light: قيمة Hex للوضع الفاتح
    ///   - dark: قيمة Hex للوضع الداكن
    /// - مثال: `Color(light: "FFFFFF", dark: "000000")`
    init(light: String, dark: String) {
        let lightColor = UIColor(hex: light)
        let darkColor = UIColor(hex: dark)
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }

    /// إنشاء لون يتكيف مع Light/Dark Mode من Color objects
    init(light: Color, dark: Color) {
        let lightUI = UIColor(light)
        let darkUI = UIColor(dark)
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkUI : lightUI
        })
    }
}

// MARK: - UIColor + Hex
extension UIColor {

    /// إنشاء UIColor من Hex string
    /// يدعم: 3 أحرف (RGB)، 6 أحرف (RRGGBB)، 8 أحرف (AARRGGBB)
    convenience init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch sanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (
                255,
                (value >> 8) * 17,
                (value >> 4 & 0xF) * 17,
                (value & 0xF) * 17
            )
        case 6: // RRGGBB
            (a, r, g, b) = (
                255,
                value >> 16,
                value >> 8 & 0xFF,
                value & 0xFF
            )
        case 8: // AARRGGBB
            (a, r, g, b) = (
                value >> 24,
                value >> 16 & 0xFF,
                value >> 8 & 0xFF,
                value & 0xFF
            )
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red:   CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue:  CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
