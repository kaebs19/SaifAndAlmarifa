//
//  MatchSearchOverlay.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI
import Lottie

// MARK: - طبقة البحث عن مباراة
struct MatchSearchOverlay: View {
    var modeName: String?
    let onCancel: () -> Void
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: AppSizes.Spacing.xl) {
                LottieView(name: "Castle", loopMode: .loop, speed: 1.0)
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.Default.goldPrimary.opacity(pulse ? 0.6 : 0.2), lineWidth: 3)
                            .scaleEffect(pulse ? 1.1 : 1.0)
                    )

                Text(AppStrings.Main.findingMatch)
                    .font(.cairo(.bold, size: AppSizes.Font.title3))
                    .foregroundStyle(.white)

                if let name = modeName {
                    Text(name)
                        .font(.cairo(.medium, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }

                // نقاط متحركة
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(AppColors.Default.goldPrimary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulse ? 1.3 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: pulse
                            )
                    }
                }

                Button(action: {
                    HapticManager.warning()
                    onCancel()
                }) {
                    Text(AppStrings.Common.cancel)
                        .font(.cairo(.semiBold, size: AppSizes.Font.body))
                        .foregroundStyle(.red)
                        .padding(.horizontal, AppSizes.Spacing.xl)
                        .padding(.vertical, AppSizes.Spacing.sm)
                        .overlay(
                            Capsule().stroke(.red.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
