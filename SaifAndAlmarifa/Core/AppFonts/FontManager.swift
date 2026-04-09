//
//  FontManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 25/01/2026.
//
//  Path: SaifAndAlmarifa/Core/AppFonts/FontManager.swift
//  المسؤول عن إدارة الخطوط في التطبيق (Cairo + Poppins)

import SwiftUI

// MARK: - Font Extension
extension Font {

    // MARK: - Cairo (للنصوص العربية)
    enum CairoWeight: String {
        case black      = "Cairo-Black"
        case extraBold  = "Cairo-ExtraBold"
        case bold       = "Cairo-Bold"
        case semiBold   = "Cairo-SemiBold"
        case medium     = "Cairo-Medium"
        case regular    = "Cairo-Regular"
        case light      = "Cairo-Light"
    }

    static func cairo(_ weight: CairoWeight, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
    }

    // MARK: - Poppins (للنصوص الإنجليزية)
    enum PoppinsWeight: String {
        case black      = "Poppins-Black"
        case extraBold  = "Poppins-ExtraBold"
        case bold       = "Poppins-Bold"
        case semiBold   = "Poppins-SemiBold"
        case medium     = "Poppins-Medium"
        case regular    = "Poppins-Regular"
        case light      = "Poppins-Light"
    }

    static func poppins(_ weight: PoppinsWeight, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

// MARK: - Usage Examples
/*
 استخدام الخطوط:

 Text("مرحباً")
     .font(.cairo(.bold, size: 18))

 Text("Hello")
     .font(.poppins(.medium, size: 16))
 */
