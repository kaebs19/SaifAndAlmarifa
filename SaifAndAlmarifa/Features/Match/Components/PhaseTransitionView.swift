//
//  PhaseTransitionView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Components/PhaseTransitionView.swift
//  شاشة سينمائية بين Phase 1 و Phase 2
//

import SwiftUI

struct PhaseTransitionView: View {
    let me: MatchPlayer
    let opponents: [MatchPlayer]
    let powers: [String: Int]   // userId → power

    @State private var stage: Stage = .initial
    @State private var titleAppear = false
    @State private var cardAppear = false
    @State private var swordsBoom = false
    @State private var startBlinking = false

    private enum Stage { case initial, revealed, charging, battleReady }

    var body: some View {
        ZStack {
            // خلفية مشتعلة
            ZStack {
                Color.black.opacity(0.92).ignoresSafeArea()

                // هالة حمراء/ذهبية تتمدّد
                RadialGradient(
                    colors: [
                        Color(hex: "FFB800").opacity(swordsBoom ? 0.35 : 0.05),
                        Color(hex: "EF4444").opacity(swordsBoom ? 0.20 : 0.05),
                        .clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: swordsBoom ? 600 : 200
                )
                .ignoresSafeArea()
                .animation(.easeOut(duration: 1.0), value: swordsBoom)
            }

            VStack(spacing: AppSizes.Spacing.lg) {
                // العنوان
                VStack(spacing: 6) {
                    Text("⚔️ انتهت المرحلة الأولى")
                        .font(.cairo(.black, size: AppSizes.Font.title2))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 4)
                    Text("استعدّوا للمواجهة!")
                        .font(.cairo(.medium, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
                .scaleEffect(titleAppear ? 1 : 0.6)
                .opacity(titleAppear ? 1 : 0)

                // Powers display مع سيوف نابضة
                HStack(spacing: AppSizes.Spacing.lg) {
                    powerColumn(player: me, isMine: true)

                    // أيقونة السيوف بانفجار
                    ZStack {
                        // glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "FFE55C"), Color(hex: "EF4444")],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 70, height: 70)
                            .scaleEffect(swordsBoom ? 1.5 : 0.8)
                            .opacity(swordsBoom ? 0 : 1)
                            .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                       value: swordsBoom)

                        Image(systemName: "swords.fill")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(hex: "FFD700").opacity(0.8),
                                    radius: swordsBoom ? 18 : 6)
                            .scaleEffect(swordsBoom ? 1.15 : 1.0)
                            .rotationEffect(.degrees(swordsBoom ? 8 : -8))
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                       value: swordsBoom)
                    }

                    if let opp = opponents.first {
                        powerColumn(player: opp, isMine: false)
                    }
                }
                .padding(AppSizes.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [.white.opacity(0.06), .white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                        .stroke(AppColors.Default.goldPrimary.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: "FFD700").opacity(0.25), radius: 18)
                .opacity(cardAppear ? 1 : 0)
                .scaleEffect(cardAppear ? 1.0 : 0.8)
                .offset(y: cardAppear ? 0 : 40)

                // الشرح
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                        Text("قلعتك تتحمّل عدد ضربات = قوّتك")
                            .font(.cairo(.medium, size: AppSizes.Font.caption))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "burst.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "F87171"))
                        Text("كل إجابة صحيحة = ضربة على قلعة الخصم")
                            .font(.cairo(.medium, size: AppSizes.Font.caption))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .opacity(cardAppear ? 1 : 0)

                // البداية
                if stage == .battleReady {
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .symbolEffect(.pulse, options: .repeating)
                        Text("ابدأ المعركة!")
                    }
                    .font(.cairo(.black, size: AppSizes.Font.title3))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "EF4444").opacity(0.6),
                            radius: startBlinking ? 18 : 10)
                    .scaleEffect(startBlinking ? 1.05 : 1.0)
                    .padding(.top, AppSizes.Spacing.md)
                    .transition(.opacity.combined(with: .scale))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            startBlinking = true
                        }
                    }
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
        .onAppear { runCinematic() }
    }

    private func runCinematic() {
        // 1. عنوان
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            titleAppear = true
        }
        // 2. كرت القوة
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.5)) {
            cardAppear = true
        }
        // 3. انفجار السيوف
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            swordsBoom = true
            HapticManager.heavy()
        }
        // 4. ابدأ المعركة
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                stage = .battleReady
            }
            HapticManager.success()
        }
    }

    private func powerColumn(player: MatchPlayer, isMine: Bool) -> some View {
        let power = powers[player.id] ?? player.hp
        let accent = isMine ? AppColors.Default.goldPrimary : Color(hex: "F87171")
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(accent, lineWidth: 2)
                    .frame(width: 56, height: 56)
                AvatarView(imageURL: player.avatarUrl, size: 50)
            }

            Text(isMine ? "أنت" : player.username)
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
                .lineLimit(1)

            VStack(spacing: 2) {
                Text("\(power)")
                    .font(.poppins(.black, size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.6), radius: 10)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("قوة")
                    .font(.cairo(.medium, size: 10))
                    .foregroundStyle(.white.opacity(0.55))
            }

            // shields representing castle HP
            HStack(spacing: 3) {
                ForEach(0..<min(power, 8), id: \.self) { _ in
                    Image(systemName: "shield.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accent)
                }
                if power > 8 {
                    Text("+\(power - 8)")
                        .font(.poppins(.bold, size: 9))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
