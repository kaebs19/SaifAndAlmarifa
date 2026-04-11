//
//  RegisterView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/Register/RegisterView.swift

import SwiftUI

// MARK: - شاشة إنشاء الحساب
struct RegisterView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel = RegisterViewModel()

    // MARK: - Navigation
    var onBack: () -> Void = {}
    var onGoToLogin: () -> Void = {}
    @State private var activeContentPage: ContentPageKey?

    // MARK: - Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSizes.Spacing.lg) {
                header
                AuthHero(
                    title: AppStrings.Auth.joinBattle,
                    subtitle: AppStrings.Auth.createAccountSubtitle,
                    size: .compact
                )
                formCard
                submitButton
                switchLink
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.xl)
        }
        .dismissKeyboardOnTap()
        .background(GradientBackground.main)
        .fullScreenCover(item: $activeContentPage) { key in
            ContentPageView(
                pageKey: key,
                title: key == .termsOfUse
                    ? AppStrings.Auth.termsOfService
                    : AppStrings.Auth.privacyPolicy
            ) { activeContentPage = nil }
        }
    }

    // MARK: الهيدر (زر رجوع)
    private var header: some View {
        HStack {
            Spacer()
            AuthBackButton(action: onBack)
        }
    }

    // MARK: بطاقة النموذج
    private var formCard: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            AuthLabeledField(label: "اسم المستخدم") {
                AppTextField(
                    placeholder: AppStrings.Auth.usernamePlaceholder,
                    text: $viewModel.username,
                    icon: "person.fill",
                    contentType: .username,
                    submitLabel: .next,
                    errorMessage: viewModel.usernameError,
                    style: .glass
                )
            }

            AuthLabeledField(label: AppStrings.Auth.emailLabel) {
                AppTextField(
                    placeholder: AppStrings.Auth.emailPlaceholder,
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    contentType: .emailAddress,
                    submitLabel: .next,
                    errorMessage: viewModel.emailError,
                    style: .glass
                )
            }

            AuthLabeledField(label: AppStrings.Auth.passwordLabel) {
                AppTextField(
                    placeholder: AppStrings.Auth.passwordHint,
                    text: $viewModel.password,
                    icon: "lock.fill",
                    isSecure: true,
                    contentType: .newPassword,
                    submitLabel: .next,
                    errorMessage: viewModel.passwordError,
                    style: .glass
                )
                PasswordStrengthBar(password: viewModel.password)
            }

            AuthLabeledField(label: "تأكيد كلمة المرور") {
                AppTextField(
                    placeholder: AppStrings.Auth.confirmPasswordPlaceholder,
                    text: $viewModel.confirmPassword,
                    icon: "lock.fill",
                    isSecure: true,
                    contentType: .newPassword,
                    submitLabel: .done,
                    errorMessage: viewModel.confirmPasswordError,
                    style: .glass
                )
                PasswordMatchIndicator(
                    password: viewModel.password,
                    confirmPassword: viewModel.confirmPassword
                )
            }

            AuthTermsCheckbox(
                isChecked: $viewModel.agreedToTerms,
                onTapTerms: { activeContentPage = .termsOfUse },
                onTapPrivacy: { activeContentPage = .privacyPolicy }
            )
            .padding(.top, AppSizes.Spacing.xs)
        }
    }

    // MARK: زر التسجيل (ظاهر دائماً — معطّل إذا البيانات خاطئة)
    private var submitButton: some View {
        GradientButton(
            title: AppStrings.Auth.createAccountButton,
            icon: "icon_swords_crossed",
            colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
            isLoading: viewModel.isLoading,
            isEnabled: viewModel.isFormValid
        ) {
            Task { await viewModel.register() }
        }
    }

    // MARK: رابط تسجيل الدخول
    private var switchLink: some View {
        AuthSwitchLink(
            question: AppStrings.Auth.alreadyHaveAccount,
            action: AppStrings.Auth.login,
            onTap: onGoToLogin
        )
    }
}

#Preview {
    RegisterView()
        .environment(\.layoutDirection, .rightToLeft)
}
