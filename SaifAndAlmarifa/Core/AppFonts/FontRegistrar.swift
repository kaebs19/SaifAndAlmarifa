//
//  FontRegistrar.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Core/AppFonts/FontRegistrar.swift
//  يسجّل الخطوط المخصصة تلقائياً عند إقلاع التطبيق
//  بديل عن تسجيلها يدوياً في Info.plist (UIAppFonts)

import UIKit
import CoreText

// MARK: - Font Registrar
enum FontRegistrar {

    /// كل أسماء ملفات الخطوط المطلوب تسجيلها
    private static let fontFiles: [String] = [
        // Cairo
        "Cairo-Black",
        "Cairo-ExtraBold",
        "Cairo-Bold",
        "Cairo-SemiBold",
        "Cairo-Medium",
        "Cairo-Regular",
        "Cairo-Light",
        // Poppins
        "Poppins-Black",
        "Poppins-ExtraBold",
        "Poppins-Bold",
        "Poppins-SemiBold",
        "Poppins-Medium",
        "Poppins-Regular",
        "Poppins-Light",
    ]

    /// يسجّل كل الخطوط في CTFontManager
    /// يُستدعى مرة واحدة عند إقلاع التطبيق
    static func registerAll() {
        for fontName in fontFiles {
            register(fontName: fontName)
        }

        #if DEBUG
        printAvailableFonts()
        #endif
    }

    // MARK: - Private

    private static func register(fontName: String) {
        guard let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") else {
            #if DEBUG
            print("⚠️ [FontRegistrar] Font not found in bundle: \(fontName).ttf")
            #endif
            return
        }

        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)

        if !success {
            #if DEBUG
            let errorDescription = error?.takeUnretainedValue().localizedDescription ?? "unknown"
            // كود 105 = مُسجّل مسبقاً (غير مهم)
            if !errorDescription.contains("already") {
                print("⚠️ [FontRegistrar] Failed to register \(fontName): \(errorDescription)")
            }
            error?.release()
            #endif
        }
    }

    #if DEBUG
    /// يطبع كل الخطوط المتوفرة حالياً - للتأكد من التسجيل الصحيح
    private static func printAvailableFonts() {
        let target = ["Cairo", "Poppins"]
        for family in UIFont.familyNames.sorted() where target.contains(where: family.contains) {
            let names = UIFont.fontNames(forFamilyName: family)
            print("✅ [Fonts] \(family): \(names)")
        }
    }
    #endif
}
