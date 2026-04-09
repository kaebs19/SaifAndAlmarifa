//
//  KeychainManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/KeychainManager.swift
//  إدارة التخزين الآمن في Keychain (JWT tokens + بيانات حساسة)

import Foundation
import Security

// MARK: - Keychain Manager
final class KeychainManager {

    // MARK: - Singleton
    static let shared = KeychainManager()
    private init() {}

    // MARK: - Service
    private let service = "com.saifAndAlmarifa.keychain"

    // MARK: - Keys
    enum Key: String, CaseIterable {
        case authToken      = "auth_token"
        case refreshToken   = "refresh_token"
        case userID         = "user_id"
    }

    // MARK: - Save
    /// حفظ قيمة في Keychain (يستبدل القيمة السابقة إن وجدت)
    @discardableResult
    func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // حذف القيمة السابقة لتجنّب duplicate
        delete(key)

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Get
    func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }

        return value
    }

    // MARK: - Delete
    @discardableResult
    func delete(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All
    /// حذف كل القيم من Keychain (عند تسجيل الخروج)
    func clearAll() {
        Key.allCases.forEach { delete($0) }
    }
}
