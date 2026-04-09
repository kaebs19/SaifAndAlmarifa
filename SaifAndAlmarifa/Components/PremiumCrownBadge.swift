//
//  PremiumCrownBadge.swift
//  DatingHala
//
//  Created by Mohammed Saleh on 16/03/2026.
//
//  Path: SaifAndAlmarifa/Components/PremiumCrownBadge.swift
//  شارة التاج المميز | Premium Crown Badge

import SwiftUI

// MARK: - Premium Crown Badge
/// شارة التاج للمستخدمين المميزين
/// يُستخدم في: SwipeCardView, UserProfileView, SwipeActionButtons
struct PremiumCrownBadge: View {

    // MARK: - Properties
    var size: CGFloat = 14
    var showGlow: Bool = false

    @State private var isGlowing = false

    // MARK: - Body
    var body: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .orange.opacity(showGlow && isGlowing ? 0.8 : 0.6), radius: 4)
            .onAppear {
                if showGlow {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isGlowing = true
                    }
                }
            }
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 20) {
        PremiumCrownBadge()
        PremiumCrownBadge(size: 20, showGlow: true)
    }
    .padding()
}
