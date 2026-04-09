//
//  AuthEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Auth/AuthEndpoint.swift
//  كل endpoints Auth - struct مستقل لكل واحد مع نوع استجابته

import Foundation

// MARK: - Auth Endpoint Namespace
enum AuthEndpoint {

    // MARK: - Register
    struct Register: Endpoint {
        typealias Response = AuthData
        let request: RegisterRequest

        var path: String   { "/auth/register" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }

    // MARK: - Login
    struct Login: Endpoint {
        typealias Response = AuthData
        let request: LoginRequest

        var path: String   { "/auth/login" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }

    // MARK: - Admin Login
    struct AdminLogin: Endpoint {
        typealias Response = AuthData
        let request: LoginRequest

        var path: String   { "/auth/admin-login" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }

    // MARK: - Get Me
    struct GetMe: Endpoint {
        typealias Response = User

        var path: String   { "/auth/me" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    // MARK: - Forgot Password
    struct ForgotPassword: Endpoint {
        typealias Response = EmptyData
        let request: ForgotPasswordRequest

        var path: String   { "/auth/forgot-password" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }

    // MARK: - Verify Reset Code
    struct VerifyResetCode: Endpoint {
        typealias Response = VerifyCodeData
        let request: VerifyResetCodeRequest

        var path: String   { "/auth/verify-reset-code" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }

    // MARK: - Reset Password
    struct ResetPassword: Endpoint {
        typealias Response = EmptyData
        let request: ResetPasswordRequest

        var path: String   { "/auth/reset-password" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }

    // MARK: - Google Login
    struct GoogleLogin: Endpoint {
        typealias Response = AuthData
        let request: GoogleLoginRequest

        var path: String   { "/auth/google" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }

    // MARK: - Apple Login
    struct AppleLogin: Endpoint {
        typealias Response = AuthData
        let request: AppleLoginRequest

        var path: String   { "/auth/apple" }
        var method: HTTPMethod { .post }
        var body: Encodable? { request }
    }
}
