//
//  QuickActionButton.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - زر إجراء سريع (مكافأة / عجلة)
struct QuickActionButton: View {
    let title: String
    let icon: String
    var badge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: AppSizes.Spacing.sm) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.Default.goldPrimary)

                    if badge {
                        Circle()
                            .fill(AppColors.Default.error)
                            .frame(width: 8, height: 8)
                            .offset(x: -2, y: -2)
                    }
                }

                Text(title)
                    .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.md)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(AppColors.Default.goldPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
