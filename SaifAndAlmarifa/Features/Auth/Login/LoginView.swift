//
//  LoginView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/Login/LoginView.swift

import SwiftUI

// MARK: - شاشة تسجيل الدخول
struct LoginView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel = LoginViewModel()

    // MARK: - Navigation
    var onBack: () -> Void = {}
    var onGoToRegister: () -> Void = {}
    var onForgotPassword: () -> Void = {}

    // MARK: - Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSizes.Spacing.lg) {
                header
                AuthHero(
                    title: AppStrings.Auth.welcomeBack,
                    subtitle: AppStrings.Auth.loginSubtitle,
                    size: .compact
                )
                formCard
                submitButton
                dividerSection
                socialButtons
                switchLink
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.xl)
        }
        .background(GradientBackground.main)
    }

    // MARK: الهيدر (عنوان التطبيق + زر رجوع)
    private var header: some View {
        ZStack {
            Text(AppStrings.Auth.appTitle)
                .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                AuthBackButton(action: onBack)
            }
        }
    }

    // MARK: بطاقة النموذج
    private var formCard: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            labeledField(AppStrings.Auth.emailLabel) {
                AppTextField(
                    placeholder: AppStrings.Auth.emailPlaceholder,
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    errorMessage: viewModel.emailError,
                    style: .glass
                )
            }

            labeledField(AppStrings.Auth.passwordLabel) {
                AppTextField(
                    placeholder: "••••••••",
                    text: $viewModel.password,
                    icon: "lock.fill",
                    isSecure: true,
                    errorMessage: viewModel.passwordError,
                    style: .glass
                )
            }

            forgotPasswordLink
        }
    }

    // MARK: حقل مع Label فوقه
    @ViewBuilder
    private func labeledField<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            Text(label)
                .font(.cairo(.semiBold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
            content()
        }
    }

    // MARK: رابط نسيت كلمة المرور
    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button(action: onForgotPassword) {
                Text(AppStrings.Auth.forgotPassword)
                    .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .underline()
            }
        }
    }

    // MARK: زر تسجيل الدخول
    private var submitButton: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.cairo(.medium, size: AppSizes.Font.caption))
                    .foregroundStyle(AppColors.Default.error)
                    .multilineTextAlignment(.center)
            }

            GradientButton(
                title: AppStrings.Auth.login,
                icon: "icon_swords_crossed",
                colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSubmit
            ) {
                Task { await viewModel.login() }
            }
        }
    }

    // MARK: فاصل "أو"
    private var dividerSection: some View {
        DividerWithText(text: AppStrings.Auth.or, style: .glass)
            .padding(.vertical, AppSizes.Spacing.xs)
    }

    // MARK: أزرار Apple + Google
    private var socialButtons: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            SocialLoginButton(type: .google, style: .light) {
                Task { await viewModel.loginWithGoogle() }
            }
            SocialLoginButton(type: .apple, style: .light) {
                Task { await viewModel.loginWithApple() }
            }
        }
    }

    // MARK: رابط إنشاء حساب
    private var switchLink: some View {
        AuthSwitchLink(
            question: AppStrings.Auth.dontHaveAccount,
            action: AppStrings.Auth.createAccount,
            onTap: onGoToRegister
        )
    }
}

#Preview {
    LoginView()
        .environment(\.layoutDirection, .rightToLeft)
}
