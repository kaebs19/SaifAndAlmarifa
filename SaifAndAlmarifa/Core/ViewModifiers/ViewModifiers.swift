//
//  ViewModifiers.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 25/01/2026.
//
//  Path: SaifAndAlmarifa/Core/ViewModifiers/ViewModifiers.swift
//  Modifiers قابلة لإعادة الاستخدام

import SwiftUI

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(.cairo(.semiBold, size: AppSizes.Font.bodyLarge))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppSizes.Button.large)
            .background(isEnabled ? AppColors.Default.primary : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.cairo(.semiBold, size: AppSizes.Font.bodyLarge))
            .foregroundStyle(AppColors.Default.primary)
            .frame(maxWidth: .infinity)
            .frame(height: AppSizes.Button.large)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(AppColors.Default.primary, lineWidth: 1.5)
            )
    }
}

// MARK: - Text Field Style
struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.cairo(.regular, size: AppSizes.Font.body))
            .padding(AppSizes.Spacing.md)
            .background(AppColors.Default.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
    }
}

// MARK: - Card Style
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.Default.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - View Extension for Modifiers
extension View {

    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self.modifier(PrimaryButtonStyle(isEnabled: isEnabled))
    }

    func secondaryButtonStyle() -> some View {
        self.modifier(SecondaryButtonStyle())
    }

    func appTextFieldStyle() -> some View {
        self.modifier(AppTextFieldStyle())
    }

    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}

// MARK: - Usage Examples
/*
 استخدام الـ Modifiers:

 // زر رئيسي
 Button("تسجيل الدخول") {
     // action
 }
 .primaryButtonStyle()

 // زر ثانوي
 Button("إنشاء حساب") {
     // action
 }
 .secondaryButtonStyle()

 // حقل إدخال
 TextField("البريد الإلكتروني", text: $email)
     .appTextFieldStyle()

 // بطاقة
 VStack {
     // content
 }
 .padding()
 .cardStyle()
 */
