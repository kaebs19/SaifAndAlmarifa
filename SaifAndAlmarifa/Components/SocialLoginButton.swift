//
//  SocialLoginButton.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/SocialLoginButton.swift
//  زر تسجيل الدخول الاجتماعي
//  ✅ محسّن: يدعم الثيم الداكن والفاتح

import SwiftUI

// MARK: - Social Login Type
enum SocialLoginType {
    case apple
    case google
    
    var title: String {
        switch self {
        case .apple: return AppStrings.Auth.continueWithApple
        case .google: return AppStrings.Auth.continueWithGoogle
        }
    }
    
    var icon: String {
        switch self {
        case .apple:  return "apple-logo"
        case .google: return "google-logo"
        }
    }

    /// هل الأيقونة أحادية اللون (تحتاج تلوين)؟
    var isTemplate: Bool {
        switch self {
        case .apple:  return true   // أبيض/أسود
        case .google: return false  // متعدد الألوان
        }
    }
}

// MARK: - Button Style
enum SocialButtonStyle {
    case light    // خلفية فاتحة
    case glass    // زجاجي (شاشات Auth)
    case auto     // يتكيف تلقائياً
}

// MARK: - Social Login Button
struct SocialLoginButton: View {
    let type: SocialLoginType
    var style: SocialButtonStyle = .auto
    var showTitle: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Computed Colors
    private var resolvedStyle: SocialButtonStyle {
        if style != .auto { return style }
        return colorScheme == .dark ? .glass : .light
    }
    
    private var backgroundColor: Color {
        switch type {
        case .apple:
            return resolvedStyle == .glass ? .white : .black
        case .google:
            return resolvedStyle == .glass ? .white.opacity(0.08) : .white
        }
    }
    
    private var foregroundColor: Color {
        switch type {
        case .apple:
            return resolvedStyle == .glass ? .black : .white
        case .google:
            return resolvedStyle == .glass ? .white : .black
        }
    }
    
    private var borderColor: Color {
        switch type {
        case .apple:
            return .clear
        case .google:
            return resolvedStyle == .glass ? .white.opacity(0.2) : Color.gray.opacity(0.3)
        }
    }
    
    private var shadowColor: Color {
        resolvedStyle == .glass ? .white.opacity(0.05) : .black.opacity(0.05)
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            HapticManager.light()
            action()
        }) {
            HStack(spacing: AppSizes.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                } else {
                    Image(type.icon)
                        .renderingMode(type.isTemplate ? .template : .original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)

                    if showTitle {
                        Text(type.title)
                            .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    }
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: AppSizes.Button.large)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
            .opacity(isLoading ? 0.7 : 1)
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Preview
#Preview("Light Style") {
    VStack(spacing: 16) {
        SocialLoginButton(type: .apple, style: .light) { }
        SocialLoginButton(type: .google, style: .light) { }
    }
    .padding()
    .background(AppColors.Default.background)
}

#Preview("Glass Style") {
    ZStack {
        GradientBackground.main
        
        VStack(spacing: 16) {
            SocialLoginButton(type: .apple, style: .glass) { }
            SocialLoginButton(type: .google, style: .glass) { }
        }
        .padding()
    }
}
