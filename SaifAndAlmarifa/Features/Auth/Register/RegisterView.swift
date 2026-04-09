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
        .background(GradientBackground.main)
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
            AppTextField(
                placeholder: AppStrings.Auth.usernamePlaceholder,
                text: $viewModel.username,
                icon: "person.fill",
                errorMessage: viewModel.usernameError,
                style: .glass
            )

            AppTextField(
                placeholder: AppStrings.Auth.emailPlaceholder,
                text: $viewModel.email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                errorMessage: viewModel.emailError,
                style: .glass
            )

            AppTextField(
                placeholder: AppStrings.Auth.passwordHint,
                text: $viewModel.password,
                icon: "lock.fill",
                isSecure: true,
                errorMessage: viewModel.passwordError,
                style: .glass
            )

            AppTextField(
                placeholder: AppStrings.Auth.confirmPasswordPlaceholder,
                text: $viewModel.confirmPassword,
                icon: "lock.fill",
                isSecure: true,
                errorMessage: viewModel.confirmPasswordError,
                style: .glass
            )

            AuthTermsCheckbox(isChecked: $viewModel.agreedToTerms)
                .padding(.top, AppSizes.Spacing.xs)
        }
    }

    // MARK: زر التسجيل
    private var submitButton: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.cairo(.medium, size: AppSizes.Font.caption))
                    .foregroundStyle(AppColors.Default.error)
                    .multilineTextAlignment(.center)
            }

            GradientButton(
                title: AppStrings.Auth.createAccountButton,
                icon: "icon_swords_crossed",
                colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSubmit
            ) {
                Task { await viewModel.register() }
            }
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
