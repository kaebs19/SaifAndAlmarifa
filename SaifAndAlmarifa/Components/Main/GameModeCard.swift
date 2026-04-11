//
//  GameModeCard.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - بطاقة وضع لعب
struct GameModeCard: View {
    let mode: GameMode
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            VStack(spacing: AppSizes.Spacing.sm) {
                Image(mode.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)

                Text(mode.title)
                    .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                    .foregroundStyle(.white)

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.lg)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(mode.accentColor.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
