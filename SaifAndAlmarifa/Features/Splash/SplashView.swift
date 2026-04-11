//
//  SplashView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Splash/SplashView.swift

import SwiftUI
import Lottie

// MARK: - شاشة Splash
struct SplashView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel = SplashViewModel()

    // MARK: - Callback
    let onFinish: (AppDestination) -> Void

    // MARK: - Animation States
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -30
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var glowPulse: Bool = false
    @State private var particlesVisible: Bool = false
    @State private var loadingOpacity: Double = 0

    // MARK: - Body
    var body: some View {
        ZStack {
            GradientBackground.main

            // جزيئات ذهبية
            particles

            VStack(spacing: AppSizes.Spacing.lg) {
                Spacer()
                logo
                title
                tagline
                Spacer()
                loader
            }
            .padding(.bottom, AppSizes.Spacing.xxl)
        }
        .task {
            startAnimation()
            await viewModel.checkSession()
        }
        .onChange(of: viewModel.destination) { _, dest in
            if let dest {
                HapticManager.success()
                onFinish(dest)
            }
        }
    }

    // MARK: الشعار + Lottie
    private var logo: some View {
        ZStack {
            // هالة متنفّسة
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.Default.goldPrimary.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: glowPulse ? 100 : 70
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .opacity(logoOpacity)

            // Lottie Castle animation
            LottieView(name: "Castle", loopMode: .loop, speed: 0.8)
                .frame(width: 180, height: 180)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .shadow(color: AppColors.Default.goldPrimary.opacity(0.6), radius: glowRadius)
        }
    }

    // MARK: العنوان
    private var title: some View {
        Text(AppStrings.Auth.appTitle)
            .font(.cairo(.black, size: 38))
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(titleOpacity)
            .offset(y: titleOffset)
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
    private var loader: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(AppColors.Default.goldPrimary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(glowPulse ? 1.2 : 0.6)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2),
                        value: glowPulse
                    )
            }
        }
        .opacity(loadingOpacity)
    }

    // MARK: جزيئات ذهبية
    private var particles: some View {
        ZStack {
            ForEach(0..<8) { i in
                Circle()
                    .fill(AppColors.Default.goldPrimary.opacity(0.15))
                    .frame(width: CGFloat.random(in: 4...10))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: particlesVisible ? CGFloat.random(in: -300...300) : 0
                    )
                    .opacity(particlesVisible ? 0.6 : 0)
                    .animation(
                        .easeOut(duration: Double.random(in: 1.5...2.5))
                        .delay(Double(i) * 0.1),
                        value: particlesVisible
                    )
            }
        }
    }

    // MARK: - تشغيل الأنيميشن
    private func startAnimation() {
        // 1 - الشعار يظهر مع دوران + تكبير
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 0
        }

        // 2 - توهج + جزيئات
        withAnimation(.easeInOut(duration: 0.8).delay(0.4)) {
            glowRadius = 25
            particlesVisible = true
        }

        // 3 - العنوان
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        // 4 - الوصف + loading
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            taglineOpacity = 1.0
            loadingOpacity = 1.0
        }

        // 5 - نبض مستمر
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
            glowPulse = true
        }
    }
}

#Preview {
    SplashView { _ in }
        .environment(\.layoutDirection, .rightToLeft)
}
