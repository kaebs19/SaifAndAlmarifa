//
//  SplashView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Splash/SplashView.swift

import SwiftUI

// MARK: - شاشة Splash
struct SplashView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel = SplashViewModel()

    // MARK: - Callback
    let onFinish: (AppDestination) -> Void

    // MARK: - Animation State
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0

    // MARK: - Body
    var body: some View {
        ZStack {
            GradientBackground.main

            VStack(spacing: AppSizes.Spacing.lg) {
                Spacer()
                logo
                title
                tagline
                Spacer()
                loadingIndicator
            }
            .padding(.bottom, AppSizes.Spacing.xxl)
        }
        .task {
            startAnimation()
            await viewModel.checkSession()
        }
        .onChange(of: viewModel.destination) { _, dest in
            if let dest { onFinish(dest) }
        }
    }

    // MARK: الشعار مع توهج ذهبي
    private var logo: some View {
        Image("icon_swords_crossed")
            .resizable()
            .scaledToFit()
            .frame(width: 140, height: 140)
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .shadow(color: AppColors.Default.goldPrimary.opacity(0.7), radius: glowRadius)
            .shadow(color: AppColors.Default.goldPrimary.opacity(0.4), radius: glowRadius * 0.5)
    }

    // MARK: اسم التطبيق
    private var title: some View {
        Text(AppStrings.Auth.appTitle)
            .font(.cairo(.black, size: 38))
            .foregroundStyle(AppColors.Default.goldPrimary)
            .opacity(titleOpacity)
    }

    // MARK: الوصف
    private var tagline: some View {
        Text(AppStrings.Auth.appTagline)
            .font(.cairo(.regular, size: AppSizes.Font.bodyLarge))
            .foregroundStyle(.white.opacity(0.6))
            .opacity(taglineOpacity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSizes.Spacing.xl)
    }

    // MARK: مؤشر التحميل
    private var loadingIndicator: some View {
        ProgressView()
            .tint(AppColors.Default.goldPrimary)
            .scaleEffect(0.8)
            .opacity(taglineOpacity)
    }

    // MARK: - تشغيل الأنيميشن
    private func startAnimation() {
        // 1 - ظهور الشعار مع تكبير
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 2 - توهج ذهبي
        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
            glowRadius = 30
        }

        // 3 - ظهور العنوان
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            titleOpacity = 1.0
        }

        // 4 - ظهور الوصف
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            taglineOpacity = 1.0
        }
    }
}

#Preview {
    SplashView { destination in
        print("Go to: \(destination)")
    }
    .environment(\.layoutDirection, .rightToLeft)
}
