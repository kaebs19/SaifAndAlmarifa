//
//  FeatureBadge.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/FeatureBadge.swift

import SwiftUI

// MARK: - بطاقة ميزة
struct FeatureBadge: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: AppSizes.Spacing.xs) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)

            Text(title)
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.md)
        .background(.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
    }
}

#Preview {
    ZStack {
        GradientBackground.main
        HStack(spacing: AppSizes.Spacing.sm) {
            FeatureBadge(icon: "icon_swords_crossed", title: "معارك مباشرة")
            FeatureBadge(icon: "icon_castle", title: "ابنِ قلعتك")
            FeatureBadge(icon: "icon_gem", title: "أسئلة متنوعة")
        }
        .padding()
    }
}
