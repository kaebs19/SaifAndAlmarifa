//
//  WelcomeViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 18/05/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/WelcomeViewModel.swift
//  ViewModel لشاشة الترحيب — يتعامل مع تسجيل Apple/Google مباشرةً
//  بدون الحاجة للانتقال إلى شاشة Login.

import Foundation
import Combine

// MARK: - ViewModel لشاشة الترحيب
@MainActor
final class WelcomeViewModel: ObservableObject {

    // MARK: - State
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    private let authService: AuthService
    private let toast = ToastManager.shared

    // MARK: - Init
    init(authService: AuthService = .shared) {
        self.authService = authService
    }

    // MARK: - ═══════════════ Apple ═══════════════
    func loginWithApple() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await AppleSignInManager.shared.signIn()
            let user = try await authService.loginWithApple(
                identityToken: result.identityToken,
                fullName: result.fullName
            )
            toast.success("مرحباً \(user.username)")
        } catch let error as AppleSignInError {
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول بـ Apple")
        } catch let error as APIError {
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            // المستخدم ألغى → لا نعرض رسالة
            let desc = error.localizedDescription.lowercased()
            if desc.contains("canceled") || desc.contains("cancelled") { return }
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - ═══════════════ Google ═══════════════
    func loginWithGoogle() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let idToken = try await GoogleSignInManager.shared.signIn()
            let user = try await authService.loginWithGoogle(idToken: idToken)
            toast.success("مرحباً \(user.username)")
        } catch let error as APIError {
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            let desc = error.localizedDescription.lowercased()
            if desc.contains("canceled") || desc.contains("cancelled") { return }
            toast.error(error.localizedDescription)
        }
    }
}
