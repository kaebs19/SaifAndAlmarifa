//
//  MatchEndView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/MatchEndView.swift
//  شاشة نهاية المباراة — فوز / خسارة + المكافآت

import SwiftUI

struct MatchEndView: View {
    let result: MatchEndResult
    var onRematch: (() -> Void)? = nil
    let onClose: () -> Void

    @State private var appear = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // overlay مظلم
            Color.black.opacity(0.85).ignoresSafeArea()

            // Confetti للفوز
            if result.didIWin && showConfetti {
                ConfettiView(count: 80)
                    .ignoresSafeArea()
                    .zIndex(1)
            }

            VStack(spacing: AppSizes.Spacing.lg) {
                // بانر
                banner
                    .scaleEffect(appear ? 1 : 0.7)
                    .opacity(appear ? 1 : 0)

                // النقاط
                scoreCard
                    .offset(y: appear ? 0 : 30)
                    .opacity(appear ? 1 : 0)

                // المكافآت
                rewardsCard
                    .offset(y: appear ? 0 : 30)
                    .opacity(appear ? 1 : 0)

                Spacer()

                // أزرار
                actionButtons
                    .offset(y: appear ? 0 : 30)
                    .opacity(appear ? 1 : 0)
            }
            .padding(AppSizes.Spacing.lg)
            .padding(.top, AppSizes.Spacing.xxl)
            .zIndex(2)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
            if result.didIWin {
                // تأخير Confetti قليلاً ليأتي بعد الـ banner animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showConfetti = true
                }
            }
        }
    }

    // MARK: - Actions
    private var actionButtons: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            // إعادة التحدي
            if let onRematch {
                Button {
                    HapticManager.medium()
                    onRematch()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("إعادة التحدّي")
                    }
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.5), radius: 10)
                }
            }

            // العودة للرئيسية
            Button {
                HapticManager.light()
                onClose()
            } label: {
                Text("العودة للرئيسية")
                    .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .overlay(
                        Capsule().stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Banner (فوز/خسارة)
    @ViewBuilder
    private var banner: some View {
        if result.didIWin {
            VStack(spacing: AppSizes.Spacing.sm) {
                UIBanner.victory.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.6), radius: 20)

                Text("🏆 فوز!")
                    .font(.cairo(.black, size: 42))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.6), radius: 10)
            }
        } else {
            VStack(spacing: AppSizes.Spacing.sm) {
                UIBanner.defeat.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180)
                    .opacity(0.8)

                Text("💔 الخسارة")
                    .font(.cairo(.black, size: 38))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - بطاقة النتائج
    private var scoreCard: some View {
        HStack(spacing: AppSizes.Spacing.lg) {
            scoreColumn(label: "أنت", score: result.myScore, isWinner: result.didIWin)
            Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: 50)
            scoreColumn(label: result.opponentName ?? "الخصم", score: result.opponentScore, isWinner: !result.didIWin)
        }
        .padding(AppSizes.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func scoreColumn(label: String, score: Int, isWinner: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.cairo(.medium, size: 11))
                .foregroundStyle(.white.opacity(0.5))
            Text("\(score)")
                .font(.poppins(.black, size: 32))
                .foregroundStyle(isWinner ? AppColors.Default.goldPrimary : .white.opacity(0.6))
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            } else {
                Color.clear.frame(height: 14)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - المكافآت
    private var rewardsCard: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            Text("المكافآت")
                .font(.cairo(.bold, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: AppSizes.Spacing.md) {
                rewardPill(emoji: "🪙", amount: result.goldReward, label: "ذهب", color: Color(hex: "FFD700"))
                rewardPill(emoji: "⭐", amount: result.xpReward, label: "خبرة", color: Color(hex: "A78BFA"))
            }
        }
        .padding(AppSizes.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
    }

    private func rewardPill(emoji: String, amount: Int, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(emoji).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 0) {
                Text("+\(amount)")
                    .font(.poppins(.black, size: 16))
                    .foregroundStyle(color)
                Text(label)
                    .font(.cairo(.regular, size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, AppSizes.Spacing.md).padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
}
