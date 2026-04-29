//
//  SessionExpiryHandler.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Auth/SessionExpiryHandler.swift
//  يستجيب لـ 401: يمسح الجلسة + يعرض toast + يحوّل لشاشة الدخول
//

import Foundation
import UIKit

@MainActor
final class SessionExpiryHandler {
    static let shared = SessionExpiryHandler()
    private init() {}

    private var isHandling: Bool = false
    private var lastHandledAt: Date?
    private let cooldownSeconds: TimeInterval = 5  // امنع تكرار خلال 5s

    /// يُستدعى من NetworkManager عند أي 401
    func handleExpiry() {
        // امنع التكرار (multiple 401 in flight)
        if isHandling { return }
        if let last = lastHandledAt, Date().timeIntervalSince(last) < cooldownSeconds {
            return
        }
        isHandling = true
        lastHandledAt = Date()

        // 1. أبلغ المستخدم
        ToastManager.shared.warning("انتهت الجلسة — سجّل الدخول من جديد")

        // 2. امسح الجلسة + اقطع الـ socket
        AppSocketManager.shared.disconnect()
        AuthManager.shared.logout()

        // 3. اسمح بإعادة الاستدعاء بعد فترة
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownSeconds) { [weak self] in
            self?.isHandling = false
        }
    }
}
