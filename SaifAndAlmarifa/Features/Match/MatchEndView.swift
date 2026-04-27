//
//  MatchEndView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/MatchEndView.swift
//  شاشة نهاية المباراة — احترافية، خلفية كاملة، Trophy متحرّك
//

import SwiftUI

struct MatchEndView: View {
    let result: MatchEndResult
    var history: [QuestionStat] = []
    var onRematch: (() -> Void)? = nil
    let onClose: () -> Void

    @State private var appear = false
    @State private var showConfetti = false
    @State private var trophyBounce = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            // خلفية كاملة opaque
            backgroundGradient.ignoresSafeArea()

            // ✨ Victory Beam للفوز (Stage E)
            if result.didIWin && showConfetti {
                VictoryBeam()
                    .zIndex(0)
            }

            // Confetti محسّن (Stage E)
            if result.didIWin && showConfetti {
                EnhancedConfetti(count: 80)
                    .zIndex(1)
            }

            // 🏰 Castle Crumble للخسارة (Stage E)
            if !result.didIWin && showConfetti {
                CastleCrumble()
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width / 2,
                              y: UIScreen.main.bounds.height * 0.35)
                    .zIndex(0)
            }

            // المحتوى — قابل للتمرير
            ScrollView {
                VStack(spacing: AppSizes.Spacing.lg) {
                    // Hero (Trophy/Defeat)
                    heroBanner
                        .scaleEffect(appear ? 1 : 0.6)
                        .opacity(appear ? 1 : 0)

                    // VS scorecard
                    versusScoreCard
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)

                    // المكافآت
                    rewardsCard
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)

                    // ملخّص الأداء
                    if !history.isEmpty {
                        MatchSummaryChart(history: history)
                            .offset(y: appear ? 0 : 30)
                            .opacity(appear ? 1 : 0)
                    }

                    Spacer(minLength: 100)
                }
                .padding(AppSizes.Spacing.lg)
                .padding(.top, AppSizes.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .zIndex(2)

            // Action buttons — ثابتة بالأسفل
            VStack {
                Spacer()
                actionButtons
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.bottom, AppSizes.Spacing.lg)
                    .background(
                        LinearGradient(
                            colors: [bottomGradientColor.opacity(0), bottomGradientColor],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .bottom)
                    )
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 30)
            }
            .zIndex(3)
        }
        .onAppear { runAnimations() }
    }

    // MARK: - Animations
    private func runAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
            appear = true
        }
        // Trophy bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                trophyBounce = true
            }
            HapticManager.success()
        }
        // Pulse for win
        if result.didIWin {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        // Confetti / Crumble (يستخدم نفس الـ flag)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showConfetti = true
        }
    }

    // MARK: - Background
    @ViewBuilder
    private var backgroundGradient: some View {
        if result.didIWin {
            // ذهبي/أخضر للفوز
            LinearGradient(
                colors: [
                    Color(hex: "0A0F1F"),
                    Color(hex: "1A1A0F"),
                    Color(hex: "08091E")
                ],
                startPoint: .top, endPoint: .bottom
            )
            .overlay(
                RadialGradient(
                    colors: [Color(hex: "FFD700").opacity(0.18), .clear],
                    center: .top, startRadius: 50, endRadius: 400
                )
            )
        } else {
            // أحمر داكن للخسارة
            LinearGradient(
                colors: [
                    Color(hex: "0F0A0F"),
                    Color(hex: "1A0A12"),
                    Color(hex: "08091E")
                ],
                startPoint: .top, endPoint: .bottom
            )
            .overlay(
                RadialGradient(
                    colors: [Color(hex: "EF4444").opacity(0.12), .clear],
                    center: .top, startRadius: 50, endRadius: 400
                )
            )
        }
    }

    private var bottomGradientColor: Color {
        result.didIWin ? Color(hex: "08091E") : Color(hex: "08091E")
    }

    // MARK: - Hero Banner
    @ViewBuilder
    private var heroBanner: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // الأيقونة الكبيرة
            ZStack {
                if result.didIWin {
                    // halo ذهبي
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "FFD700").opacity(pulse ? 0.5 : 0.25), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: pulse ? 110 : 80
                            )
                        )
                        .frame(width: 220, height: 220)
                        .blur(radius: 8)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 110, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "B8860B")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: 18)
                        .rotationEffect(.degrees(trophyBounce ? -5 : 5))
                        .scaleEffect(trophyBounce ? 1.0 : 0.9)
                        .animation(
                            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                            value: trophyBounce
                        )
                } else {
                    Circle()
                        .fill(Color(hex: "EF4444").opacity(0.18))
                        .frame(width: 180, height: 180)
                        .blur(radius: 14)

                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 90, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "F87171"), Color(hex: "EF4444")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "EF4444").opacity(0.5), radius: 14)
                        .opacity(0.85)
                }
            }
            .frame(height: 160)

            // العنوان
            Text(result.didIWin ? "فوز!" : "خسارة")
                .font(.cairo(.black, size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: result.didIWin
                            ? [Color(hex: "FFE55C"), Color(hex: "FFD700")]
                            : [Color(hex: "F87171"), Color(hex: "EF4444")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: (result.didIWin ? Color(hex: "FFD700") : Color(hex: "EF4444"))
                            .opacity(0.5), radius: 12)

            // عنوان فرعي
            Text(result.didIWin ? "هدمت قلعة الخصم 🏰" : "صمدت قلعتك للنهاية")
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    // MARK: - VS Score Card
    private var versusScoreCard: some View {
        HStack(spacing: 0) {
            scoreColumn(
                label: "أنت",
                score: result.myScore,
                isWinner: result.didIWin,
                accent: AppColors.Default.goldPrimary
            )

            // VS divider
            VStack {
                Rectangle().fill(.white.opacity(0.08)).frame(width: 1, height: 30)
                Text("VS")
                    .font(.poppins(.black, size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 4)
                Rectangle().fill(.white.opacity(0.08)).frame(width: 1, height: 30)
            }

            scoreColumn(
                label: result.opponentName ?? "الخصم",
                score: result.opponentScore,
                isWinner: !result.didIWin,
                accent: Color(hex: "F87171")
            )
        }
        .padding(.vertical, AppSizes.Spacing.md)
        .padding(.horizontal, AppSizes.Spacing.lg)
        .background(
            LinearGradient(
                colors: [.white.opacity(0.06), .white.opacity(0.02)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func scoreColumn(label: String, score: Int, isWinner: Bool, accent: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(accent)
                }
                Text(label)
                    .font(.cairo(.bold, size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            Text("\(score)")
                .font(.poppins(.black, size: 42))
                .foregroundStyle(isWinner ? accent : .white.opacity(0.5))
                .monospacedDigit()
                .shadow(color: isWinner ? accent.opacity(0.5) : .clear, radius: 10)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rewards
    private var rewardsCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                Text("المكافآت")
                    .font(.cairo(.bold, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.7))
            }
            HStack(spacing: AppSizes.Spacing.md) {
                rewardPill(icon: "circle.hexagongrid.fill", amount: result.goldReward,
                           label: "ذهب", color: Color(hex: "FFD700"))
                rewardPill(icon: "star.fill", amount: result.xpReward,
                           label: "خبرة", color: Color(hex: "A78BFA"))
            }
        }
        .padding(AppSizes.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func rewardPill(icon: String, amount: Int, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text("+\(amount)")
                    .font(.poppins(.black, size: 18))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(label)
                    .font(.cairo(.medium, size: 10))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.horizontal, AppSizes.Spacing.md).padding(.vertical, 8)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.35), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions
    private var actionButtons: some View {
        VStack(spacing: 10) {
            if let onRematch {
                Button {
                    HapticManager.medium()
                    onRematch()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 18, weight: .black))
                        Text("إعادة التحدّي")
                            .font(.cairo(.black, size: AppSizes.Font.body))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 12)
                }
            }

            Button {
                HapticManager.light()
                onClose()
            } label: {
                Text("العودة للرئيسية")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
    }
}
