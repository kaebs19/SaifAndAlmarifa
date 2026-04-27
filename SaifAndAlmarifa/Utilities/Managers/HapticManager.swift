//
//  HapticManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/HapticManager.swift
//  اهتزازات لمسية — نجاح / خطأ / تنبيه / نقر

import UIKit

// MARK: - Haptic Manager
enum HapticManager {

    // MARK: - نجاح
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - خطأ
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - تنبيه
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: - نقر خفيف
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - نقر متوسط
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - نقر ثقيل
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    // MARK: - اختيار (toggle/picker)
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - اضطراب درامي (3 ضربات ثقيلة متتابعة) — للضربة القاضية
    static func criticalHit() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { gen.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { gen.impactOccurred() }
    }

    // MARK: - تكّات combo (متتابعة ناعمة) — للسلسلة
    static func comboTick(count: Int) {
        let gen = UIImpactFeedbackGenerator(style: .light)
        let n = max(1, min(count, 5))
        for i in 0..<n {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                gen.impactOccurred(intensity: 0.5 + Double(i) * 0.1)
            }
        }
    }

    // MARK: - دفعة قوية موجزة — لمراحل الانتقال
    static func phaseShift() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        heavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { medium.impactOccurred() }
    }
}
