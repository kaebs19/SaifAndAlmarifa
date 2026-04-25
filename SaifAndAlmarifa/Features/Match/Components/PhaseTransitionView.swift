//
//  PhaseTransitionView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Components/PhaseTransitionView.swift
//  شاشة وسطية بين المرحلة 1 والمرحلة 2 — تعرض القوة المتراكمة

import SwiftUI

struct PhaseTransitionView: View {
    let me: MatchPlayer
    let opponents: [MatchPlayer]
    let powers: [String: Int]   // userId → power
    @State private var appear = false
    @State private var showStartButton = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: AppSizes.Spacing.lg) {
                // Title
                VStack(spacing: 4) {
                    Text("⚔️ انتهت المرحلة الأولى")
                        .font(.cairo(.black, size: AppSizes.Font.title2))
                        .foregroundStyle(.white)
                    Text("استعدّوا للمواجهة!")
                        .font(.cairo(.medium, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
                .scaleEffect(appear ? 1 : 0.7)
                .opacity(appear ? 1 : 0)

                // Power display
                HStack(spacing: AppSizes.Spacing.lg) {
                    powerColumn(player: me, isMine: true)
                    Image(systemName: "swords.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    if let opp = opponents.first {
                        powerColumn(player: opp, isMine: false)
                    }
                }
                .padding(AppSizes.Spacing.lg)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)

                // Explainer
                VStack(spacing: 4) {
                    Text("قلعتك تتحمّل عدد ضربات = قوّتك")
                        .font(.cairo(.medium, size: AppSizes.Font.caption))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("كل إجابة صحيحة = ضربة على قلعة الخصم")
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .opacity(appear ? 1 : 0)

                if showStartButton {
                    Text("ستبدأ المعركة قريباً...")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                        .padding(.top, AppSizes.Spacing.md)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showStartButton = true }
            }
        }
    }

    private func powerColumn(player: MatchPlayer, isMine: Bool) -> some View {
        let power = powers[player.id] ?? player.hp
        return VStack(spacing: 6) {
            AvatarView(imageURL: player.avatarUrl, size: 50)
                .overlay(
                    Circle().stroke(isMine ? AppColors.Default.goldPrimary : Color(hex: "F87171"), lineWidth: 2)
                )

            Text(isMine ? "أنت" : player.username)
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
                .lineLimit(1)

            VStack(spacing: 2) {
                Text("\(power)")
                    .font(.poppins(.black, size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.5), radius: 8)
                Text("قوة")
                    .font(.cairo(.medium, size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Hearts representing castle HP
            HStack(spacing: 2) {
                ForEach(0..<min(power, 8), id: \.self) { _ in
                    Image(systemName: "shield.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(isMine ? AppColors.Default.goldPrimary : Color(hex: "F87171"))
                }
                if power > 8 {
                    Text("+\(power - 8)")
                        .font(.poppins(.bold, size: 8))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
