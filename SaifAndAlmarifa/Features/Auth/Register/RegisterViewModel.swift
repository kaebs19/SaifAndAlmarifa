//
//  RegisterViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/Register/RegisterViewModel.swift

import Foundation
import Combine

// MARK: - ViewModel لشاشة التسجيل
@MainActor
final class RegisterViewModel: ObservableObject {

    // MARK: - Input
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var agreedToTerms: Bool = false

    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Field Errors
    @Published var usernameError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?

    // MARK: - Dependencies
    private let authService: AuthService

    // MARK: - Init
    init(authService: AuthService = .shared) {
        self.authService = authService
    }

    // MARK: - هل يمكن الإرسال
    var canSubmit: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        agreedToTerms &&
        !isLoading
    }

    // MARK: - Dependencies (Toast)
    private let toast = ToastManager.shared

    // MARK: - تنفيذ التسجيل
    func register() async {
        guard validate() else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await authService.register(
                username: username,
                email: email,
                password: password,
                country: "SA"
            )
            toast.success("مرحباً \(user.username)", subtitle: "تم إنشاء الحساب بنجاح")
        } catch let error as APIError {
            errorMessage = error.errorDescription
            toast.error(error.errorDescription ?? "حدث خطأ", subtitle: error.details?.first)
        } catch {
            errorMessage = error.localizedDescription
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - التحقق من المدخلات
    private func validate() -> Bool {
        usernameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil

        var isValid = true

        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            usernameError = AppStrings.Errors.usernameRequired
            isValid = false
        } else if !AuthValidator.isValidUsername(username) {
            usernameError = AppStrings.Errors.usernameTooShort
            isValid = false
        }

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
        } else if !AuthValidator.isValidPassword(password) {
            passwordError = AppStrings.Errors.passwordTooShort
            isValid = false
        }

        if confirmPassword != password {
            confirmPasswordError = AppStrings.Errors.passwordsDoNotMatch
            isValid = false
        }

        if !agreedToTerms {
            errorMessage = AppStrings.Errors.mustAgreeTerms
            isValid = false
        }

        if !isValid {
            let firstError = usernameError ?? emailError ?? passwordError ?? confirmPasswordError ?? errorMessage
            toast.warning(firstError ?? "تحقق من المدخلات")
        }

        return isValid
    }
}
