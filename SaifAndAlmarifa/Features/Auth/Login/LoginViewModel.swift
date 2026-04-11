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

    // MARK: - هل النموذج صالح
    @Published private(set) var isFormValid: Bool = false

    // MARK: - Dependencies
    private let authService: AuthService
    private let toast = ToastManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Remember Email
    private let lastEmailKey = "last_login_email"

    // MARK: - Init
    init(authService: AuthService = .shared) {
        self.authService = authService
        self.email = UserDefaults.standard.string(forKey: lastEmailKey) ?? ""
        setupLiveValidation()
    }

    /// حفظ الإيميل بعد نجاح الدخول
    private func rememberEmail() {
        UserDefaults.standard.set(email, forKey: lastEmailKey)
    }

    // MARK: - ═══════════════ التحقق اللحظي ═══════════════

    private func setupLiveValidation() {
        Publishers.CombineLatest($email, $password)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] mail, pass in
                guard let self else { return }
                emailError = mail.isEmpty ? nil : FormValidator.validate(mail, rules: FormValidator.emailRules).error
                passwordError = pass.isEmpty ? nil : (pass.isEmpty ? nil : nil)

                isFormValid = !mail.isEmpty && !pass.isEmpty && emailError == nil
            }
            .store(in: &cancellables)
    }

    // MARK: - ═══════════════ تسجيل الدخول ═══════════════

    func login() async {
        let emailResult = FormValidator.validate(email, rules: FormValidator.emailRules)
        if !emailResult.isValid {
            emailError = emailResult.error
            toast.warning(emailResult.error ?? "تحقق من البريد")
            return
        }
        if password.isEmpty {
            passwordError = AppStrings.Errors.passwordRequired
            toast.warning(AppStrings.Errors.passwordRequired)
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await authService.login(email: email, password: password)
            rememberEmail()
            toast.success("مرحباً \(user.username)")
        } catch let error as APIError {
            errorMessage = error.errorDescription
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            errorMessage = error.localizedDescription
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - ═══════════════ Google ═══════════════

    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let idToken = try await GoogleSignInManager.shared.signIn()
            let user = try await authService.loginWithGoogle(idToken: idToken)
            toast.success("مرحباً \(user.username)")
        } catch let error as APIError {
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            if error.localizedDescription.contains("canceled") { return }
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - ═══════════════ Apple ═══════════════

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
            toast.error(error.errorDescription ?? "فشل تسجيل الدخول")
        } catch {
            if error.localizedDescription.contains("canceled") { return }
            toast.error(error.localizedDescription)
        }
    }
}
