//
//  SplashViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Splash/SplashViewModel.swift

import Foundation
import Combine

// MARK: - حالة التطبيق بعد Splash
enum AppDestination {
    case auth
    case main
}

// MARK: - ViewModel لشاشة Splash
@MainActor
final class SplashViewModel: ObservableObject {

    // MARK: - State
    @Published var isAnimating = false
    @Published var destination: AppDestination?

    // MARK: - Dependencies
    private let authManager = AuthManager.shared
    private let authService = AuthService.shared

    // MARK: - مدة الأنيميشن
    private let animationDuration: UInt64 = 2_000_000_000 // 2 ثانية

    // MARK: - التحقق من الجلسة
    func checkSession() async {
        // بدء الأنيميشن
        isAnimating = true

        // التحقق بالتوازي مع الأنيميشن
        async let sessionCheck: Void = verifyToken()
        async let minDelay: Void = Task.sleep(nanoseconds: animationDuration)

        // انتظر الأطول (الأنيميشن أو التحقق)
        await sessionCheck
        _ = try? await minDelay

        // تحديد الوجهة
        destination = authManager.isAuthenticated ? .main : .auth
    }

    // MARK: - Private
    private func verifyToken() async {
        guard authManager.currentToken != nil else { return }
        // محاولة جلب بيانات المستخدم للتحقق من صلاحية التوكن
        do {
            _ = try await authService.getMe()
        } catch let error as APIError where error == .unauthorized {
            // ✅ التوكن منتهي فعلاً (401) → تسجيل خروج.
            //    (NetworkManager يستدعي SessionExpiryHandler أصلاً عند 401،
            //     لكن نبقي هذا صريحاً كضمان)
            authManager.logout()
        } catch {
            // ⚠️ خطأ شبكة/مؤقت (لا إنترنت، انتهاء مهلة، خطأ خادم 5xx)
            //    → لا نسجّل خروج! التوكن ما زال صالحاً، نبقي الجلسة المخزّنة
            //    ونعتمد على البيانات المحفوظة محلياً (offline-first).
        }
    }
}
