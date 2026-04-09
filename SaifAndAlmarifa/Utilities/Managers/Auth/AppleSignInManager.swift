//
//  AppleSignInManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Auth/AppleSignInManager.swift
//  تسجيل الدخول عبر Apple - يستخدم إطار AuthenticationServices المدمج في iOS

import Foundation
import AuthenticationServices
import UIKit

// MARK: - نتيجة تسجيل الدخول عبر Apple
struct AppleSignInResult {
    let identityToken: String
    let fullName: String?
}

// MARK: - Apple Sign In Manager
@MainActor
final class AppleSignInManager: NSObject {

    // MARK: - Singleton
    static let shared = AppleSignInManager()
    private override init() { super.init() }

    // MARK: - Continuation
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    // MARK: - بدء تسجيل الدخول
    func signIn() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

// MARK: - Delegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8)
        else {
            continuation?.resume(throwing: APIError.unknown("فشل الحصول على توكن Apple"))
            continuation = nil
            return
        }

        let components = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ].compactMap { $0 }
        let fullName = components.joined(separator: " ")

        continuation?.resume(
            returning: AppleSignInResult(
                identityToken: token,
                fullName: fullName.isEmpty ? nil : fullName
            )
        )
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// MARK: - Presentation Context
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
