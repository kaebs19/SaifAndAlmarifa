//
//  AuthManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Auth/AuthManager.swift
//  مدير حالة المصادقة — حفظ/استعادة/حذف بيانات المستخدم تلقائياً

import Foundation
import Combine

// MARK: - Auth Manager
@MainActor
final class AuthManager: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthManager()

    // MARK: - Published
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?

    // MARK: - Dependencies
    private let keychain: KeychainManager
    private let userKey = "cached_user_data"

    // MARK: - Init
    private init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
        loadSession()
    }

    // MARK: - Token
    var currentToken: String? {
        keychain.get(.authToken)
    }

    // MARK: - حفظ جلسة جديدة (login / register)
    func saveSession(token: String, user: User) {
        keychain.save(token, for: .authToken)
        keychain.save(user.id, for: .userID)
        saveUserLocally(user)
        currentUser = user
        isAuthenticated = true
        AppSocketManager.shared.connect()
        Task { await ClanStateManager.shared.loadMyClan() }
    }

    // MARK: - تحديث بيانات المستخدم (getMe)
    func updateCurrentUser(_ user: User) {
        saveUserLocally(user)
        currentUser = user
    }

    // MARK: - تسجيل الخروج (مسح كل شيء)
    func logout() {
        AppSocketManager.shared.disconnect()
        ClanStateManager.shared.clear()
        keychain.clearAll()
        clearUserLocally()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Private

    /// تحميل الجلسة عند إقلاع التطبيق
    private func loadSession() {
        guard keychain.get(.authToken) != nil else {
            isAuthenticated = false
            return
        }
        currentUser = loadUserLocally()
        isAuthenticated = true
        AppSocketManager.shared.connect()
        Task { await ClanStateManager.shared.loadMyClan() }
    }

    /// حفظ User في UserDefaults (كـ JSON)
    private func saveUserLocally(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: userKey)
    }

    /// قراءة User من UserDefaults
    private func loadUserLocally() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    /// حذف User من UserDefaults
    private func clearUserLocally() {
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}
