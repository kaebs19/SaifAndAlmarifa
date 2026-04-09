//
//  AuthService.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Auth/AuthService.swift
//  الواجهة عالية المستوى لكل عمليات Auth
//  يُستخدم من قِبَل الـ ViewModels (LoginViewModel, RegisterViewModel, ...)

import Foundation

// MARK: - Auth Service
@MainActor
final class AuthService: APIService {

    // MARK: - Singleton
    static let shared = AuthService()

    // MARK: - Dependencies
    let network: NetworkClient
    private let authManager: AuthManager

    // MARK: - Init
    init(
        network: NetworkClient = NetworkManager.shared,
        authManager: AuthManager = .shared
    ) {
        self.network = network
        self.authManager = authManager
    }

    // MARK: - ═══════════════ Register ═══════════════
    @discardableResult
    func register(
        username: String,
        email: String,
        password: String,
        country: String
    ) async throws -> User {
        let endpoint = AuthEndpoint.Register(
            request: RegisterRequest(
                username: username,
                email: email,
                password: password,
                country: country
            )
        )
        let data = try await network.request(endpoint)
        authManager.saveSession(token: data.token, user: data.user)
        return data.user
    }

    // MARK: - ═══════════════ Login ═══════════════
    @discardableResult
    func login(email: String, password: String) async throws -> User {
        let endpoint = AuthEndpoint.Login(
            request: LoginRequest(email: email, password: password)
        )
        let data = try await network.request(endpoint)
        authManager.saveSession(token: data.token, user: data.user)
        return data.user
    }

    // MARK: - ═══════════════ Admin Login ═══════════════
    @discardableResult
    func adminLogin(email: String, password: String) async throws -> User {
        let endpoint = AuthEndpoint.AdminLogin(
            request: LoginRequest(email: email, password: password)
        )
        let data = try await network.request(endpoint)
        authManager.saveSession(token: data.token, user: data.user)
        return data.user
    }

    // MARK: - ═══════════════ Get Me ═══════════════
    @discardableResult
    func getMe() async throws -> User {
        let user = try await network.request(AuthEndpoint.GetMe())
        authManager.updateCurrentUser(user)
        return user
    }

    // MARK: - ═══════════════ Forgot Password ═══════════════
    func forgotPassword(email: String) async throws {
        let endpoint = AuthEndpoint.ForgotPassword(
            request: ForgotPasswordRequest(email: email)
        )
        try await network.requestVoid(endpoint)
    }

    // MARK: - ═══════════════ Verify Reset Code ═══════════════
    /// يتحقق من رمز إعادة التعيين ويُرجع `resetToken` للخطوة التالية
    func verifyResetCode(email: String, code: String) async throws -> String {
        let endpoint = AuthEndpoint.VerifyResetCode(
            request: VerifyResetCodeRequest(email: email, code: code)
        )
        let data = try await network.request(endpoint)
        return data.resetToken
    }

    // MARK: - ═══════════════ Reset Password ═══════════════
    func resetPassword(resetToken: String, newPassword: String) async throws {
        let endpoint = AuthEndpoint.ResetPassword(
            request: ResetPasswordRequest(
                resetToken: resetToken,
                newPassword: newPassword
            )
        )
        try await network.requestVoid(endpoint)
    }

    // MARK: - ═══════════════ Google Login ═══════════════
    @discardableResult
    func loginWithGoogle(idToken: String) async throws -> User {
        let endpoint = AuthEndpoint.GoogleLogin(
            request: GoogleLoginRequest(idToken: idToken)
        )
        let data = try await network.request(endpoint)
        authManager.saveSession(token: data.token, user: data.user)
        return data.user
    }

    // MARK: - ═══════════════ Apple Login ═══════════════
    @discardableResult
    func loginWithApple(
        identityToken: String,
        fullName: String? = nil
    ) async throws -> User {
        let endpoint = AuthEndpoint.AppleLogin(
            request: AppleLoginRequest(
                identityToken: identityToken,
                fullName: fullName
            )
        )
        let data = try await network.request(endpoint)
        authManager.saveSession(token: data.token, user: data.user)
        return data.user
    }

    // MARK: - ═══════════════ Logout ═══════════════
    func logout() {
        authManager.logout()
    }
}
