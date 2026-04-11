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
}
