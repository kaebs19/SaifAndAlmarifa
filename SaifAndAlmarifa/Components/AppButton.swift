//
//  AppButton.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/AppButton.swift
//  مكون الزر القابل لإعادة الاستخدام

import SwiftUI

// MARK: - Button Type
enum AppButtonType {
    case primary
    case secondary
    case text
}

// MARK: - App Button
struct AppButton: View {

    // MARK: - Properties
    let title: String
    var type: AppButtonType = .primary
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: AppSizes.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.cairo(.semiBold, size: AppSizes.Font.bodyLarge))
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: AppSizes.Button.large)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(borderOverlay)
            .shadow(
                color: type == .primary
                    ? AppColors.Default.primary.opacity(isEnabled ? 0.35 : 0)
                    : .clear,
                radius: 10,
                y: 5
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    // MARK: - Actions
    private func handleTap() {
        guard isEnabled, !isLoading else { return }
        action()
    }

    // MARK: - Style

    @ViewBuilder
    private var buttonBackground: some View {
        switch type {
        case .primary:
            LinearGradient(
                colors: [AppColors.Default.primary, AppColors.Default.secondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary, .text:
            Color.clear
        }
    }

    private var textColor: Color {
        switch type {
        case .primary:
            return .white
        case .secondary, .text:
            return AppColors.Default.primary
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if type == .secondary {
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(AppColors.Default.primary, lineWidth: 1.5)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        AppButton(title: "تسجيل الدخول", type: .primary) { }
        AppButton(title: "إنشاء حساب", type: .secondary) { }
        AppButton(title: "تخطي", type: .text) { }
        AppButton(title: "مع أيقونة", icon: "arrow.left") { }
        AppButton(title: "جاري التحميل...", isLoading: true) { }
        AppButton(title: "معطل", isEnabled: false) { }
    }
    .padding()
    .background(AppColors.Default.background)
}
