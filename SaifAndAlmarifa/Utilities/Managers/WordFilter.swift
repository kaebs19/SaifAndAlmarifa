//
//  WordFilter.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/WordFilter.swift
//  فلتر كلمات بسيط (client-side) — الـ backend يجب أن يطبق فلترة أقوى

import Foundation

enum WordFilter {

    /// قائمة كلمات غير مسموح بها (مختصرة — السيرفر يوسّعها)
    private static let banned: [String] = [
        // كلمات مسيئة مختارة (بالعربي + الإنجليزي)
        "spam", "scam",
        // إضافة قائمة أوسع على السيرفر
    ]

    /// هل النص يحتوي كلمة محظورة؟
    static func contains(bannedWord text: String) -> String? {
        let lower = text.lowercased()
        for word in banned where lower.contains(word.lowercased()) {
            return word
        }
        return nil
    }

    /// تنظيف النص باستبدال الكلمات بـ ***
    static func sanitize(_ text: String) -> String {
        var result = text
        for word in banned {
            let stars = String(repeating: "*", count: word.count)
            result = result.replacingOccurrences(
                of: word, with: stars, options: .caseInsensitive
            )
        }
        return result
    }
}
