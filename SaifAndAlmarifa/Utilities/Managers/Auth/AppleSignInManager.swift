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

// MARK: - أخطاء Apple Sign In
enum AppleSignInError: LocalizedError {
    case timeout
    case noPresentationAnchor
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "تسجيل الدخول بـ Apple لم يستجب. تأكّد من تسجيل دخولك في iCloud من إعدادات النظام ثم حاول مجدداً."
        case .noPresentationAnchor:
            return "تعذّر فتح نافذة تسجيل الدخول"
        case .unknown(let msg):
            return msg
        }
    }
}

// MARK: - Apple Sign In Manager
@MainActor
final class AppleSignInManager: NSObject {

    // MARK: - Singleton
    static let shared = AppleSignInManager()
    private override init() { super.init() }

    // MARK: - Continuation
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    // يجب الاحتفاظ بـ controller وإلا يُحذف قبل وصول الـ callback (خصوصاً على iPad)
    private var authController: ASAuthorizationController?
    // مهمة timeout لتفادي البقاء عالقاً في حالة عدم استدعاء النظام للـ delegate
    private var timeoutTask: Task<Void, Never>?

    // MARK: - بدء تسجيل الدخول
    /// ⚠️ هذا التابع يحتوي على **timeout صارم** (15 ثانية)؛
    ///   على iPad بدون حساب iCloud (وفي حالات أخرى) قد لا يستدعي النظام أيّ
    ///   delegate callback، مما يجعل الـ continuation يبقى معلّقاً للأبد
    ///   ويتسبّب في تجميد الواجهة (isLoading عالقة).
    func signIn() async throws -> AppleSignInResult {
        // إلغاء أي عملية سابقة
        resetState()

        return try await withCheckedThrowingContinuation { cont in
            continuation = cont

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            authController = controller

            // بدء مهمة timeout
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15s
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.handleTimeout()
                }
            }

            controller.performRequests()
        }
    }

    // MARK: - Reset
    private func resetState() {
        timeoutTask?.cancel()
        timeoutTask = nil
        authController = nil
    }

    private func handleTimeout() {
        guard let cont = continuation else { return }
        continuation = nil
        resetState()
        cont.resume(throwing: AppleSignInError.timeout)
    }
}

// MARK: - Delegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        timeoutTask?.cancel(); timeoutTask = nil

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8)
        else {
            continuation?.resume(throwing: AppleSignInError.unknown("فشل الحصول على توكن Apple"))
            continuation = nil
            resetState()
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
        resetState()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        timeoutTask?.cancel(); timeoutTask = nil
        continuation?.resume(throwing: error)
        continuation = nil
        resetState()
    }
}

// MARK: - Presentation Context
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // ✅ على iPad (خاصةً Stage Manager / multi-scene)، يجب الحصول على
        //   window حقيقي ومرئي ومرتبط بـ scene نشط.
        //   الـ fallback لـ ASPresentationAnchor() (window خالي) يفشل بصمت.
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        // 1) جرّب الـ scene النشط في الواجهة الأمامية
        let foregroundActive = scenes.first { $0.activationState == .foregroundActive }
        if let win = bestWindow(in: foregroundActive) { return win }

        // 2) أي scene في الواجهة الأمامية (حتى لو غير نشط)
        let foregroundInactive = scenes.first { $0.activationState == .foregroundInactive }
        if let win = bestWindow(in: foregroundInactive) { return win }

        // 3) أي scene كان
        for scene in scenes {
            if let win = bestWindow(in: scene) { return win }
        }

        // 4) آخر محاولة: keyWindow عبر كل الـ scenes
        let anyKeyWindow = scenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow && !$0.isHidden }
        if let win = anyKeyWindow { return win }

        // 5) لو وصلنا هنا، رجّع أي UIWindow مرئي بدل ASPresentationAnchor()
        //    الفارغ الذي يفشل بصمت على iPad.
        let anyVisibleWindow = scenes
            .flatMap { $0.windows }
            .first { !$0.isHidden }
        return anyVisibleWindow ?? ASPresentationAnchor()
    }

    /// يختار أفضل window من scene: keyWindow ومرئي → أول window مرئي.
    private func bestWindow(in scene: UIWindowScene?) -> UIWindow? {
        guard let scene else { return nil }
        if let key = scene.windows.first(where: { $0.isKeyWindow && !$0.isHidden }) {
            return key
        }
        return scene.windows.first(where: { !$0.isHidden })
    }
}
