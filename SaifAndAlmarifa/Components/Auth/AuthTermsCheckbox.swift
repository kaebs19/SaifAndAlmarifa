//
//  AuthTermsCheckbox.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/AuthTermsCheckbox.swift

import SwiftUI

// MARK: - مربع الموافقة على الشروط
struct AuthTermsCheckbox: View {
    @Binding var isChecked: Bool
    var onTapTerms: () -> Void = {}
    var onTapPrivacy: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: AppSizes.Spacing.sm) {
            checkbox
            termsText
            Spacer(minLength: 0)
        }
    }

    // MARK: المربع
    private var checkbox: some View {
        Button {
            isChecked.toggle()
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .stroke(AppColors.Default.goldPrimary, lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .overlay {
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                    }
                }
        }
    }

    // MARK: نص الشروط
    private var termsText: some View {
        (Text(AppStrings.Auth.agreeTo + " ")
            .foregroundColor(.white.opacity(0.75))
         + Text(AppStrings.Auth.termsOfService)
            .foregroundColor(AppColors.Default.goldPrimary)
            .underline()
         + Text(" " + AppStrings.Auth.and + " ")
            .foregroundColor(.white.opacity(0.75))
         + Text(AppStrings.Auth.privacyPolicy)
            .foregroundColor(AppColors.Default.goldPrimary)
            .underline())
            .font(.cairo(.regular, size: AppSizes.Font.caption))
    }
}

#Preview {
    ZStack {
        GradientBackground.main
        AuthTermsCheckbox(isChecked: .constant(false))
            .padding()
    }
}
