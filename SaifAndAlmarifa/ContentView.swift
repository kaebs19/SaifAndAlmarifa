//
//  ContentView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 03/04/2026.
//

import SwiftUI

// MARK: - حالات الشاشة الجذرية
enum AppScreen {
    case splash
    case auth
    case main
}

// MARK: - الشاشة الجذرية
struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var currentScreen: AppScreen = .splash

    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashView { destination in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentScreen = destination == .main ? .main : .auth
                    }
                }
                .transition(.opacity)

            case .auth:
                AuthFlow()
                    .transition(.opacity)

            case .main:
                // TODO: استبدال لاحقاً بـ MainTabView
                mainPlaceholder
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentScreen)
        // عند تسجيل الخروج → العودة للـ auth
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            withAnimation {
                currentScreen = isAuth ? .main : .auth
            }
        }
    }

    // MARK: شاشة مؤقتة بعد تسجيل الدخول
    private var mainPlaceholder: some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            Image("icon_swords_crossed")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Text("مرحباً \(authManager.currentUser?.username ?? "محارب")")
                .font(.cairo(.bold, size: AppSizes.Font.title1))
                .foregroundStyle(AppColors.Default.goldPrimary)

            Button {
                AuthService.shared.logout()
            } label: {
                Text("تسجيل الخروج")
                    .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GradientBackground.main)
    }
}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
