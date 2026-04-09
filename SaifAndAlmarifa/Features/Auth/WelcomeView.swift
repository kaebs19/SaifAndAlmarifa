//
//  WelcomeView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/WelcomeView.swift

import SwiftUI

// MARK: - شاشة الترحيب
struct WelcomeView: View {

    // MARK: - Actions
    var onRegister: () -> Void = {}
    var onLogin: () -> Void = {}
    var onApple: () -> Void = {}
    var onGoogle: () -> Void = {}

    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topContent
                    Spacer(minLength: AppSizes.Spacing.lg)
                    AuthBottomSheet { sheetContent }
                }
                .frame(minHeight: proxy.size.height)
            }
        }
        .background(GradientBackground.main)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: المحتوى العلوي
    private var topContent: some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            AuthHero()
                .padding(.top, AppSizes.Spacing.xl)
            featureBadges
                .padding(.top, AppSizes.Spacing.md)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.bottom, AppSizes.Spacing.lg)
        .frame(maxWidth: .infinity)
    }

    // MARK: بطاقات المزايا
    private var featureBadges: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            FeatureBadge(
                icon: "icon_swords_crossed",
                title: AppStrings.Features.liveBattles
            )
            FeatureBadge(
                icon: "icon_castle",
                title: AppStrings.Features.buildCastle
            )
            FeatureBadge(
                icon: "icon_gem",
                title: AppStrings.Features.variousQuestions
            )
        }
    }

    // MARK: محتوى الـ sheet
    private var sheetContent: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Text(AppStrings.Auth.startJourney)
                .font(.cairo(.bold, size: AppSizes.Font.title1))
                .foregroundStyle(.white)

            Text(AppStrings.Auth.startJourneySubtitle)
                .font(.cairo(.regular, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, AppSizes.Spacing.sm)

            GradientButton(
                title: AppStrings.Auth.createAccount,
                colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                action: onRegister
            )

            outlinedLoginButton

            DividerWithText(text: AppStrings.Auth.orContinueWith, style: .glass)
                .padding(.vertical, AppSizes.Spacing.xs)

            socialButtons
        }
    }

    // MARK: زر تسجيل الدخول (محاط بحد)
    private var outlinedLoginButton: some View {
        Button(action: onLogin) {
            Text(AppStrings.Auth.login)
                .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(AppColors.Default.goldPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppSizes.Button.large)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                        .stroke(AppColors.Default.goldPrimary, lineWidth: 1.5)
                )
        }
    }

    // MARK: أزرار التواصل الاجتماعي
    private var socialButtons: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            SocialLoginButton(type: .apple, style: .light, showTitle: false, action: onApple)
            SocialLoginButton(type: .google, style: .light, showTitle: false, action: onGoogle)
        }
    }
}

#Preview {
    WelcomeView()
        .environment(\.layoutDirection, .rightToLeft)
}
