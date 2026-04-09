//
//  AuthHero.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/AuthHero.swift

import SwiftUI

// MARK: - حجم الـ Hero
enum AuthHeroSize {
    case large    // شاشة الترحيب
    case compact  // شاشات التسجيل/الدخول

    var logo: CGFloat    { self == .large ? 100 : 72 }
    var titleSize: CGFloat { self == .large ? 34 : 26 }
    var spacing: CGFloat { self == .large ? AppSizes.Spacing.md : AppSizes.Spacing.sm }
}

// MARK: - رأس شاشات Auth (شعار + عنوان + وصف)
struct AuthHero: View {
    var logo: String = "icon_swords_crossed"
    var title: String = AppStrings.Auth.appTitle
    var subtitle: String = AppStrings.Auth.appTagline
    var size: AuthHeroSize = .large

    var body: some View {
        VStack(spacing: size.spacing) {
            logoView
            titleView
            subtitleView
        }
    }

    // MARK: الشعار مع توهج
    private var logoView: some View {
        Image(logo)
            .resizable()
            .scaledToFit()
            .frame(width: size.logo, height: size.logo)
            .foregroundStyle(AppColors.Default.goldPrimary)
            .shadow(color: AppColors.Default.goldPrimary.opacity(0.6), radius: 24)
            .shadow(color: AppColors.Default.goldPrimary.opacity(0.4), radius: 8)
    }

    // MARK: العنوان
    private var titleView: some View {
        Text(title)
            .font(.cairo(.black, size: size.titleSize))
            .foregroundStyle(AppColors.Default.goldPrimary)
            .multilineTextAlignment(.center)
    }

    // MARK: الوصف
    private var subtitleView: some View {
        Text(subtitle)
            .font(.cairo(.regular, size: AppSizes.Font.bodyLarge))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
    }
}

#Preview {
    ZStack {
        GradientBackground.main
        VStack(spacing: 40) {
            AuthHero(size: .large)
            AuthHero(
                title: AppStrings.Auth.joinBattle,
                subtitle: AppStrings.Auth.createAccountSubtitle,
                size: .compact
            )
        }
    }
}
