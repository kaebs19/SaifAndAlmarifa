//
//  ToastView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Components/ToastView.swift
//  عرض رسالة Toast مع أنيميشن + ViewModifier لتطبيقها على أي شاشة

import SwiftUI

// MARK: - شكل الرسالة
struct ToastView: View {
    let message: ToastMessage
    var onDismiss: () -> Void = {}

    var body: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            icon
            texts
            Spacer(minLength: 0)
            dismissButton
        }
        .padding(AppSizes.Spacing.md)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    // MARK: الأيقونة
    private var icon: some View {
        Image(systemName: iconName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(iconColor)
    }

    // MARK: النصوص
    private var texts: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(message.title)
                .font(.cairo(.semiBold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
                .lineLimit(2)

            if let subtitle = message.subtitle {
                Text(subtitle)
                    .font(.cairo(.regular, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
    }

    // MARK: زر الإغلاق
    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - ألوان حسب النوع
    private var iconName: String {
        switch message.type {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch message.type {
        case .success: return AppColors.Default.success
        case .error:   return AppColors.Default.error
        case .warning: return AppColors.Default.warning
        case .info:    return AppColors.Default.info
        }
    }

    private var backgroundColor: Color {
        Color(hex: "1A1E3A")
    }

    private var borderColor: Color {
        iconColor.opacity(0.3)
    }
}

// MARK: - ViewModifier لعرض Toast تلقائياً
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let toast = toastManager.currentToast {
                ToastView(message: toast) {
                    toastManager.dismiss()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.currentToast)
                .zIndex(999)
                .padding(.top, AppSizes.Spacing.xl)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.currentToast)
    }
}

// MARK: - Extension
extension View {
    /// تطبيق نظام Toast على أي View
    func withToast() -> some View {
        self.modifier(ToastModifier())
    }
}

#Preview {
    ZStack {
        GradientBackground.main

        VStack(spacing: 16) {
            ToastView(message: .init(type: .success, title: "تم بنجاح", subtitle: "تم إنشاء الحساب"))
            ToastView(message: .init(type: .error, title: "خطأ", subtitle: "البريد مستخدم مسبقاً"))
            ToastView(message: .init(type: .warning, title: "تنبيه", subtitle: "محاولات كثيرة"))
            ToastView(message: .init(type: .info, title: "معلومة", subtitle: "تم إرسال رمز التحقق"))
        }
    }
}
