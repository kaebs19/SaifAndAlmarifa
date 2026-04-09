//
//  ForgotPasswordViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/ForgotPassword/ForgotPasswordViewModel.swift

import Foundation
import Combine

// MARK: - خطوات الاستعادة
enum ForgotPasswordStep {
    case email
    case code
    case password
}

// MARK: - ViewModel لاستعادة كلمة المرور (3 خطوات)
@MainActor
final class ForgotPasswordViewModel: ObservableObject {

    // MARK: - Step
    @Published var currentStep: ForgotPasswordStep = .email

    // MARK: - Inputs
    @Published var email: String = ""
    @Published var code: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""

    // MARK: - Internal
    @Published private(set) var resetToken: String?

    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var emailError: String?
    @Published var codeError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?

    // MARK: - Dependencies
    private let authService: AuthService

    // MARK: - Init
    init(authService: AuthService = .shared) {
        self.authService = authService
    }

    // MARK: - Computed

    var canSubmitEmail: Bool {
        !email.isEmpty && !isLoading
    }

    var canSubmitCode: Bool {
        code.count >= 4 && !isLoading
    }

    var canSubmitPassword: Bool {
        !newPassword.isEmpty && !confirmPassword.isEmpty && !isLoading
    }

    // MARK: - الخطوة 1: طلب رمز التحقق
    func requestCode() async {
        guard validateEmail() else { return }
        await run {
            try await authService.forgotPassword(email: email)
            currentStep = .code
        }
    }

    // MARK: - الخطوة 2: تأكيد الرمز
    func verifyCode() async {
        guard validateCode() else { return }
        await run {
            let token = try await authService.verifyResetCode(email: email, code: code)
            resetToken = token
            currentStep = .password
        }
    }

    // MARK: - الخطوة 3: تعيين كلمة مرور جديدة
    /// يُرجع `true` عند النجاح حتى تعود الشاشة لتسجيل الدخول
    func resetPassword() async -> Bool {
        guard validatePassword(), let token = resetToken else { return false }
        var didSucceed = false
        await run {
            try await authService.resetPassword(resetToken: token, newPassword: newPassword)
            didSucceed = true
        }
        return didSucceed
    }

    // MARK: - الرجوع للخطوة السابقة
    func goBack() {
        switch currentStep {
        case .email:   break
        case .code:    currentStep = .email
        case .password: currentStep = .code
        }
    }

    // MARK: - Private Helpers

    /// يُغلّف عملية async مع isLoading و errorMessage
    private func run(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - التحقق

    private func validateEmail() -> Bool {
        emailError = nil
        if email.isEmpty {
            emailError = AppStrings.Errors.emailRequired
            return false
        }
        if !AuthValidator.isValidEmail(email) {
            emailError = AppStrings.Errors.emailInvalid
            return false
        }
        return true
    }

    private func validateCode() -> Bool {
        codeError = nil
        if code.isEmpty {
            codeError = AppStrings.Errors.codeRequired
            return false
        }
        if code.count < 4 {
            codeError = AppStrings.Errors.codeInvalid
            return false
        }
        return true
    }

    private func validatePassword() -> Bool {
        passwordError = nil
        confirmPasswordError = nil
        if !AuthValidator.isValidPassword(newPassword) {
            passwordError = AppStrings.Errors.passwordTooShort
            return false
        }
        if newPassword != confirmPassword {
            confirmPasswordError = AppStrings.Errors.passwordsDoNotMatch
            return false
        }
        return true
    }
}
