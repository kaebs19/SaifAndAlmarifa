//
//  AuthManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Auth/AuthManager.swift
//  مدير حالة المصادقة في التطبيق
//  - يراقب حالة تسجيل الدخول (للـ Views)
//  - مستقل تماماً عن طبقة الشبكة (NetworkManager يقرأ التوكن مباشرة من Keychain)

import Foundation
import Combine

// MARK: - Auth Manager
@MainActor
final class AuthManager: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthManager()

    // MARK: - Published State
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?

    // MARK: - Dependencies
    private let keychain: KeychainManager

    // MARK: - Init
    private init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
        loadSession()
    }

    // MARK: - Token Access
    /// التوكن الحالي (إن وجد) - يُقرأ من Keychain
    var currentToken: String? {
        keychain.get(.authToken)
    }

    // MARK: - Session Management

    /// حفظ جلسة جديدة بعد نجاح تسجيل الدخول / التسجيل
    func saveSession(token: String, user: User) {
        keychain.save(token, for: .authToken)
        keychain.save(user.id, for: .userID)
        currentUser = user
        isAuthenticated = true
    }

    /// تحديث بيانات المستخدم الحالي (مثلاً بعد getMe)
    func updateCurrentUser(_ user: User) {
        currentUser = user
    }

    /// تسجيل الخروج - مسح كل بيانات الجلسة
    func logout() {
        keychain.clearAll()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Private

    private func loadSession() {
        isAuthenticated = keychain.get(.authToken) != nil
    }
}
