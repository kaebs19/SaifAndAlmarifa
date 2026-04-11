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
    @Published var selectedCountry: Country = CountryList.detect()
    @Published var agreedToTerms: Bool = false

    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Field Errors (لحظي)
    @Published var usernameError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?

    // MARK: - هل النموذج صالح (يتحكم بإظهار/إخفاء الزر)
    @Published private(set) var isFormValid: Bool = false

    // MARK: - Dependencies
    private let authService: AuthService
    private let toast = ToastManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(authService: AuthService = .shared) {
        self.authService = authService
        setupLiveValidation()
    }

    // MARK: - ═══════════════ التحقق اللحظي ═══════════════

    private func setupLiveValidation() {
        // مراقبة كل الحقول معاً
        Publishers.CombineLatest4($username, $email, $password, $confirmPassword)
            .combineLatest($agreedToTerms)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] (fields, agreed) in
                self?.validateAll(fields: fields, agreed: agreed)
            }
            .store(in: &cancellables)
    }

    private func validateAll(fields: (String, String, String, String), agreed: Bool) {
        let (user, mail, pass, confirm) = fields

        // لا نعرض أخطاء للحقول الفارغة (المستخدم لم يكتب بعد)
        usernameError = user.isEmpty ? nil : FormValidator.validate(user, rules: FormValidator.usernameRules).error
        emailError = mail.isEmpty ? nil : FormValidator.validate(mail, rules: FormValidator.emailRules).error
        passwordError = pass.isEmpty ? nil : FormValidator.validate(pass, rules: FormValidator.passwordRules).error
        confirmPasswordError = confirm.isEmpty ? nil : FormValidator.validate(confirm, rules: FormValidator.confirmPasswordRules(matching: pass)).error

        // الزر يظهر فقط عند تعبئة صحيحة
        isFormValid = !user.isEmpty && !mail.isEmpty && !pass.isEmpty && !confirm.isEmpty
            && usernameError == nil && emailError == nil
            && passwordError == nil && confirmPasswordError == nil
            && agreed
    }

    // MARK: - ═══════════════ تنفيذ التسجيل ═══════════════

    func register() async {
        // تحقق نهائي
        let results = [
            FormValidator.validate(username, rules: FormValidator.usernameRules),
            FormValidator.validate(email, rules: FormValidator.emailRules),
            FormValidator.validate(password, rules: FormValidator.passwordRules),
            FormValidator.validate(confirmPassword, rules: FormValidator.confirmPasswordRules(matching: password))
        ]

        if let firstError = results.first(where: { !$0.isValid })?.error {
            toast.warning(firstError)
            return
        }

        if !agreedToTerms {
            toast.warning(AppStrings.Errors.mustAgreeTerms)
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await authService.register(
                username: username,
                email: email,
                password: password,
                country: selectedCountry.id
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
}
