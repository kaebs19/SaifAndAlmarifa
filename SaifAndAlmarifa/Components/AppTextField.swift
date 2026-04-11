//
//  AppTextField.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/AppTextField.swift
//  مكون حقل الإدخال القابل لإعادة الاستخدام
//  ✅ محسّن: يدعم الثيم الداكن والفاتح

import SwiftUI

// MARK: - Text Field Style
enum FieldTheme {
    case light    // خلفية فاتحة (الشاشات العادية)
    case glass    // زجاجي (شاشات Auth مع GradientBackground)
    case auto     // يتكيف مع النظام تلقائياً
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .done
    var errorMessage: String? = nil
    var style: FieldTheme = .auto
    var onSubmit: (() -> Void)? = nil
    @State private var isPasswordVisible = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Computed Colors
    /// خلفية الحقل
    private var fieldBackground: Color {
        switch resolvedStyle {
        case .glass:
            return .white.opacity(0.08)
        case .light:
            return Color.gray.opacity(0.1)
        case .auto:
            return Color.gray.opacity(0.1) // fallback
        }
    }
    
    /// لون النص
    private var textColor: Color {
        switch resolvedStyle {
        case .glass:
            return .white
        case .light:
            return AppColors.Default.textPrimary
        case .auto:
            return AppColors.Default.textPrimary
        }
    }
    
    /// لون الأيقونات والـ placeholder
    private var secondaryColor: Color {
        switch resolvedStyle {
        case .glass:
            return .white.opacity(0.4)
        case .light:
            return .gray
        case .auto:
            return .gray
        }
    }
    
    /// لون الحدود
    private var borderColor: Color {
        switch resolvedStyle {
        case .glass:
            return .white.opacity(0.15)
        case .light:
            return .clear
        case .auto:
            return .clear
        }
    }
    
    /// لون نص الخطأ
    private var errorColor: Color {
        return AppColors.Default.error
    }
    
    /// الستايل المحسوب (auto → light أو glass حسب النظام)
    private var resolvedStyle: FieldTheme {
        if style != .auto { return style }
        return colorScheme == .dark ? .glass : .light
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            HStack(spacing: AppSizes.Spacing.sm) {
                // أيقونة (اختياري)
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(secondaryColor)
                        .frame(width: AppSizes.Icon.medium)
                }
                
                // حقل الإدخال
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .font(.cairo(.regular, size: AppSizes.Font.body))
                        .foregroundStyle(textColor)
                        .textContentType(contentType)
                        .submitLabel(submitLabel)
                        .onSubmit { onSubmit?() }
                } else {
                    TextField(placeholder, text: $text)
                        .font(.cairo(.regular, size: AppSizes.Font.body))
                        .foregroundStyle(textColor)
                        .keyboardType(keyboardType)
                        .textContentType(contentType)
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                        .autocorrectionDisabled(keyboardType == .emailAddress || isSecure)
                        .submitLabel(submitLabel)
                        .onSubmit { onSubmit?() }
                }
                
                // زر إظهار/إخفاء كلمة المرور
                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(secondaryColor)
                    }
                }
            }
            .padding(AppSizes.Spacing.md)
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(
                        errorMessage != nil
                            ? errorColor
                            : borderColor,
                        lineWidth: errorMessage != nil ? 1.5 : 1
                    )
            )
            
            // رسالة الخطأ
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.cairo(.regular, size: AppSizes.Font.caption))
                }
                .foregroundStyle(errorColor)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.2), value: error)
            }
        }
    }
}

// MARK: - Preview
#Preview("Light Style") {
    VStack(spacing: 16) {
        AppTextField(
            placeholder: "البريد الإلكتروني",
            text: .constant(""),
            icon: "envelope",
            style: .light
        )
        
        AppTextField(
            placeholder: "كلمة المرور",
            text: .constant(""),
            icon: "lock",
            isSecure: true,
            errorMessage: "كلمة المرور مطلوبة",
            style: .light
        )
    }
    .padding()
    .background(AppColors.Default.background)
}

#Preview("Glass Style") {
    ZStack {
        GradientBackground.main
        
        VStack(spacing: 16) {
            AppTextField(
                placeholder: "البريد الإلكتروني",
                text: .constant(""),
                icon: "envelope",
                style: .glass
            )
            
            AppTextField(
                placeholder: "كلمة المرور",
                text: .constant("test"),
                icon: "lock",
                isSecure: true,
                errorMessage: "كلمة المرور قصيرة جداً",
                style: .glass
            )
        }
        .padding()
    }
}
