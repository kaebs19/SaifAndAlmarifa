//
//  ForgotPasswordView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/ForgotPassword/ForgotPasswordView.swift

import SwiftUI

// MARK: - شاشة استعادة كلمة المرور (3 خطوات)
struct ForgotPasswordView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel = ForgotPasswordViewModel()

    // MARK: - Navigation
    var onBack: () -> Void = {}
    var onComplete: () -> Void = {}

    // MARK: - Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSizes.Spacing.lg) {
                header
                hero
                stepIndicator
                formCard
                submitButton
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.xl)
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
        }
        .background(GradientBackground.main)
    }

    // MARK: الهيدر
    private var header: some View {
        HStack {
            Spacer()
            AuthBackButton(action: handleBack)
        }
    }

    // MARK: Hero - يتغيّر حسب الخطوة
    private var hero: some View {
        AuthHero(
            title: heroTitle,
            subtitle: heroSubtitle,
            size: .compact
        )
    }

    private var heroTitle: String {
        switch viewModel.currentStep {
        case .email:    return AppStrings.Auth.forgotTitle
        case .code:     return AppStrings.Auth.verifyCodeTitle
        case .password: return AppStrings.Auth.newPasswordTitle
        }
    }

    private var heroSubtitle: String {
        switch viewModel.currentStep {
        case .email:
            return AppStrings.Auth.forgotSubtitle
        case .code:
            return "\(AppStrings.Auth.verifyCodeSubtitlePrefix)\n\(viewModel.email)"
        case .password:
            return AppStrings.Auth.newPasswordSubtitle
        }
    }

    // MARK: مؤشّر الخطوات (1 2 3)
    private var stepIndicator: some View {
        HStack(spacing: AppSizes.Spacing.xs) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index == stepIndex
                          ? AppColors.Default.goldPrimary
                          : .white.opacity(0.2))
                    .frame(width: index == stepIndex ? 28 : 10, height: 6)
            }
        }
    }

    private var stepIndex: Int {
        switch viewModel.currentStep {
        case .email: 0
        case .code: 1
        case .password: 2
        }
    }

    // MARK: بطاقة النموذج - محتوى يتبع الخطوة
    @ViewBuilder
    private var formCard: some View {
        switch viewModel.currentStep {
        case .email:    emailStep
        case .code:     codeStep
        case .password: passwordStep
        }
    }

    // MARK: الخطوة 1 - البريد
    private var emailStep: some View {
        AppTextField(
            placeholder: AppStrings.Auth.emailPlaceholder,
            text: $viewModel.email,
            icon: "envelope.fill",
            keyboardType: .emailAddress,
            errorMessage: viewModel.emailError,
            style: .glass
        )
    }

    // MARK: الخطوة 2 - الرمز
    private var codeStep: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            AppTextField(
                placeholder: AppStrings.Auth.codePlaceholder,
                text: $viewModel.code,
                icon: "number",
                keyboardType: .numberPad,
                errorMessage: viewModel.codeError,
                style: .glass
            )

            resendCodeRow
        }
    }

    private var resendCodeRow: some View {
        HStack(spacing: AppSizes.Spacing.xs) {
            Text(AppStrings.Auth.didNotReceiveCode)
                .font(.cairo(.regular, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.7))

            Button {
                Task { await viewModel.requestCode() }
            } label: {
                Text(AppStrings.Auth.resendCode)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .underline()
            }
        }
    }

    // MARK: الخطوة 3 - كلمة المرور الجديدة
    private var passwordStep: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            AppTextField(
                placeholder: AppStrings.Auth.newPasswordPlaceholder,
                text: $viewModel.newPassword,
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
        }
    }

    // MARK: زر الإجراء الرئيسي
    private var submitButton: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.cairo(.medium, size: AppSizes.Font.caption))
                    .foregroundStyle(AppColors.Default.error)
                    .multilineTextAlignment(.center)
            }

            GradientButton(
                title: submitTitle,
                colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                isLoading: viewModel.isLoading,
                isEnabled: submitEnabled,
                action: handleSubmit
            )
        }
    }

    private var submitTitle: String {
        switch viewModel.currentStep {
        case .email:    return AppStrings.Auth.sendCode
        case .code:     return AppStrings.Auth.verifyCodeButton
        case .password: return AppStrings.Auth.savePassword
        }
    }

    private var submitEnabled: Bool {
        switch viewModel.currentStep {
        case .email:    return viewModel.canSubmitEmail
        case .code:     return viewModel.canSubmitCode
        case .password: return viewModel.canSubmitPassword
        }
    }

    // MARK: - Actions

    private func handleBack() {
        if viewModel.currentStep == .email {
            onBack()
        } else {
            viewModel.goBack()
        }
    }

    private func handleSubmit() {
        Task {
            switch viewModel.currentStep {
            case .email:
                await viewModel.requestCode()
            case .code:
                await viewModel.verifyCode()
            case .password:
                if await viewModel.resetPassword() {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environment(\.layoutDirection, .rightToLeft)
}
