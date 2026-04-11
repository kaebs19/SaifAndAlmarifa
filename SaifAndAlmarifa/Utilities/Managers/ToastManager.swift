//
//  ToastManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/ToastManager.swift
//  مدير رسائل Toast — يعرض رسائل مؤقتة من أي مكان في التطبيق

import Foundation
import Combine
import SwiftUI

// MARK: - نوع الرسالة
enum ToastType {
    case success
    case error
    case warning
    case info
}

// MARK: - نموذج الرسالة
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let subtitle: String?
    let duration: Double

    init(type: ToastType, title: String, subtitle: String? = nil, duration: Double = 3.0) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager
@MainActor
final class ToastManager: ObservableObject {

    // MARK: - Singleton
    static let shared = ToastManager()
    private init() {}

    // MARK: - Published
    @Published var currentToast: ToastMessage?

    // MARK: - عرض رسالة
    func show(_ type: ToastType, title: String, subtitle: String? = nil, duration: Double = 3.0) {
        // Haptic تلقائي حسب النوع
        switch type {
        case .success: HapticManager.success()
        case .error:   HapticManager.error()
        case .warning: HapticManager.warning()
        case .info:    HapticManager.light()
        }

        currentToast = ToastMessage(type: type, title: title, subtitle: subtitle, duration: duration)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if currentToast?.title == title {
                dismiss()
            }
        }
    }

    // MARK: - اختصارات
    func success(_ title: String, subtitle: String? = nil) {
        show(.success, title: title, subtitle: subtitle)
    }

    func error(_ title: String, subtitle: String? = nil) {
        show(.error, title: title, subtitle: subtitle, duration: 4.0)
    }

    func warning(_ title: String, subtitle: String? = nil) {
        show(.warning, title: title, subtitle: subtitle)
    }

    func info(_ title: String, subtitle: String? = nil) {
        show(.info, title: title, subtitle: subtitle)
    }

    // MARK: - إخفاء
    func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            currentToast = nil
        }
    }
}
