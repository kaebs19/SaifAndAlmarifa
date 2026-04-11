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
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentScreen)
        .withToast()
        // عند تسجيل الخروج → العودة للـ auth
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            withAnimation {
                currentScreen = isAuth ? .main : .auth
            }
        }
    }

}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
