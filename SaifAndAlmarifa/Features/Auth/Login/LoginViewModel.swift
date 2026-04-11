//
//  LoginViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/Login/LoginViewModel.swift

import Foundation
import Combine

// MARK: - ViewModel لشاشة تسجيل الدخول
@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Input
    @Published var email: String = ""
    @Published var password: String = ""

    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var emailError: String?
    @Published var passwordError: String?

    // MARK: - Dependencies
    private let authService: AuthService
    private let toast = ToastManager.shared

    // MARK: - Init
    init(authService: AuthService = .shared) {
        self.authService = authService
    }

    // MARK: - هل يمكن الإرسال
    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    // MARK: - تنفيذ تسجيل الدخول
    func login() async {
        guard validate() else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await authService.login(email: email, password: password)
            toast.success("مرحباً \(user.username)")
        } catch let error as APIError {
            errorMessage = error.errorDescription
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            errorMessage = error.localizedDescription
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - تسجيل الدخول عبر Google
    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let idToken = try await GoogleSignInManager.shared.signIn()
            let user = try await authService.loginWithGoogle(idToken: idToken)
            toast.success("مرحباً \(user.username)")
        } catch let error as APIError {
            errorMessage = error.errorDescription
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            if error.localizedDescription.contains("canceled") { return }
            errorMessage = error.localizedDescription
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - تسجيل الدخول عبر Apple
    func loginWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await AppleSignInManager.shared.signIn()
            let user = try await authService.loginWithApple(
                identityToken: result.identityToken,
                fullName: result.fullName
            )
            toast.success("مرحباً \(user.username)")
        } catch let error as APIError {
            errorMessage = error.errorDescription
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            if error.localizedDescription.contains("canceled") { return }
            errorMessage = error.localizedDescription
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - التحقق من المدخلات
    private func validate() -> Bool {
        emailError = nil
        passwordError = nil
        var isValid = true

        if email.isEmpty {
            emailError = AppStrings.Errors.emailRequired
            isValid = false
        } else if !AuthValidator.isValidEmail(email) {
            emailError = AppStrings.Errors.emailInvalid
            isValid = false
        }

        if password.isEmpty {
            passwordError = AppStrings.Errors.passwordRequired
            isValid = false
        }

        if !isValid {
            toast.warning(emailError ?? passwordError ?? "تحقق من المدخلات")
        }

        return isValid
    }
}
