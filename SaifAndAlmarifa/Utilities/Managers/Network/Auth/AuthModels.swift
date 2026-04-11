//
//  AuthModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Auth/AuthModels.swift
//  نماذج الطلبات والاستجابات لـ Auth API

import Foundation

// MARK: - ═══════════════ Requests ═══════════════

// MARK: Register
struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
    let country: String
}

// MARK: Login
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// MARK: Forgot Password
struct ForgotPasswordRequest: Encodable {
    let email: String
}

// MARK: Verify Reset Code
struct VerifyResetCodeRequest: Encodable {
    let email: String
    let code: String
}

// MARK: Reset Password
struct ResetPasswordRequest: Encodable {
    let resetToken: String
    let newPassword: String
}

// MARK: Google Login
struct GoogleLoginRequest: Encodable {
    let idToken: String
}

// MARK: Apple Login
struct AppleLoginRequest: Encodable {
    let identityToken: String
    let fullName: String?
}

// MARK: - ═══════════════ Responses ═══════════════

// MARK: - User
struct User: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let email: String
    let role: String?
    let avatarUrl: String?
    let country: String?
    let level: Int?
    let gems: Int?
    let createdAt: String?
}

// MARK: - Auth Response
/// الاستجابة بعد login / register / google / apple
struct AuthData: Decodable {
    let token: String
    let user: User
}

// MARK: - Verify Code Response
/// الاستجابة بعد verify-reset-code
struct VerifyCodeData: Decodable {
    let resetToken: String
}
