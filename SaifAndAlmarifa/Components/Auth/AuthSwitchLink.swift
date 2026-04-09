//
//  AuthSwitchLink.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/AuthSwitchLink.swift

import SwiftUI

// MARK: - رابط التنقل بين Login/Register
struct AuthSwitchLink: View {
    let question: String
    let action: String
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: AppSizes.Spacing.xs) {
            Text(question)
                .font(.cairo(.regular, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.7))

            Button(action: onTap) {
                Text(action)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .underline()
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground.main
        AuthSwitchLink(
            question: AppStrings.Auth.alreadyHaveAccount,
            action: AppStrings.Auth.login
        ) { }
    }
}
