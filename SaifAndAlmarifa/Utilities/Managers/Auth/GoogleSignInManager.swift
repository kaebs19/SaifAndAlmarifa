//
//  GoogleSignInManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Auth/GoogleSignInManager.swift
//  تسجيل الدخول عبر Google

import Foundation
import UIKit
import GoogleSignIn

// MARK: - Google Sign In Manager
@MainActor
final class GoogleSignInManager {

    // MARK: - Singleton
    static let shared = GoogleSignInManager()

    // MARK: - Client ID (يُقرأ من Info.plist → GIDClientID)
    private var clientID: String {
        Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
            ?? "720728750667-oo4ou6sibftqj8rp1u737b0thks1fqul.apps.googleusercontent.com"
    }

    // MARK: - Init
    private init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    // MARK: - بدء تسجيل الدخول
    func signIn() async throws -> String {
        guard let rootVC = Self.topViewController() else {
            throw APIError.unknown("لم يتم إيجاد Root View Controller")
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw APIError.unknown("فشل الحصول على توكن Google")
        }
        return idToken
    }

    // MARK: - تسجيل الخروج
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - معالجة URL الـ callback
    @discardableResult
    static func handle(url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Helper
    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
