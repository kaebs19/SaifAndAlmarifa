//
//  AuthBottomSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/AuthBottomSheet.swift

import SwiftUI

// MARK: - الحاوية السفلية لشاشات Auth
struct AuthBottomSheet<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            handle
            content()
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.top, AppSizes.Spacing.md)
        .padding(.bottom, AppSizes.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            Color(hex: "0E1236")
                .clipShape(
                    .rect(
                        topLeadingRadius: 32,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 32
                    )
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: شريط علوي صغير
    private var handle: some View {
        Capsule()
            .fill(.white.opacity(0.25))
            .frame(width: 44, height: 4)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        GradientBackground.main
        AuthBottomSheet {
            Text("محتوى")
                .foregroundStyle(.white)
        }
    }
}
