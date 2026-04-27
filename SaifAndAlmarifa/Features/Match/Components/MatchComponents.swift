//
//  MatchComponents.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Components/MatchComponents.swift
//  مكوّنات UI لشاشة المباراة

import SwiftUI

// MARK: - Timer Chip مع ring + pulse حرج
struct TimerChip: View {
    let timeRemaining: Int
    let color: Color
    var timeLimit: Int = 15   // 🆕 للـ ring progress

    @State private var pulse: Bool = false

    private var isUrgent: Bool { timeRemaining <= 5 }
    private var progress: Double {
        guard timeLimit > 0 else { return 0 }
        return Double(timeRemaining) / Double(timeLimit)
    }

    var body: some View {
        ZStack {
            // 🕓 Ring تنازلي (Stage C)
            Circle()
                .stroke(color.opacity(0.18), lineWidth: 3)
                .frame(width: 44, height: 44)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.9), value: progress)

            // الرقم في الوسط
            Text("\(timeRemaining)")
                .font(.poppins(.black, size: 17))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .scaleEffect(isUrgent && pulse ? 1.18 : 1.0)
        .shadow(color: isUrgent ? color.opacity(0.7) : .clear, radius: isUrgent ? 10 : 0)
        .onChange(of: timeRemaining) { _, _ in
            if isUrgent {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { pulse = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { pulse = false }
                }
            }
        }
    }
}

// MARK: - ScoreBadge — يومض + يعدّ + يطفو "+N" + streak ring
struct ScoreBadge: View {
    let score: Int
    let color: Color
    var compact: Bool = false
    var streakActive: Bool = false   // 🆕 لو في streak ≥3

    @State private var lastScore: Int = 0
    @State private var flash: Bool = false
    @State private var floatNonce: Int = 0
    @State private var floatAmount: Int = 0

    private var size: CGFloat { compact ? 14 : 22 }

    var body: some View {
        ZStack {
            // 🔥 Streak fire ring (Stage B)
            StreakFireRing(active: streakActive && !compact)

            // الرقم
            Text("\(score)")
                .font(.poppins(.black, size: size))
                .foregroundStyle(flash ? Color.green : color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .scaleEffect(flash ? 1.35 : 1.0)
                .shadow(color: flash ? Color.green.opacity(0.8) : .clear, radius: 8)

            // ➕N float-up (Stage B)
            if !compact {
                FloatingPoints(nonce: floatNonce, amount: floatAmount,
                               color: Color(hex: "FFE55C"))
                    .offset(y: -16)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: flash)
        .onChange(of: score) { old, new in
            guard new > old else { return }
            floatAmount = new - old
            floatNonce += 1
            flash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                flash = false
            }
        }
    }
}

// MARK: - زر إجابة
struct AnswerButton: View {
    let index: Int         // 0,1,2,3
    let text: String
    let state: AnswerState
    let onTap: () -> Void

    enum AnswerState {
        case idle
        case selected
        case correct
        case wrong
        case disabled     // للـ 50/50
    }

    private var letter: String {
        ["A", "B", "C", "D"][safe: index] ?? "?"
    }

    private var accentColor: Color {
        switch state {
        case .idle:     return .white.opacity(0.18)
        case .selected: return AppColors.Default.goldPrimary
        case .correct:  return AppColors.Default.success
        case .wrong:    return AppColors.Default.error
        case .disabled: return .white.opacity(0.05)
        }
    }

    @ViewBuilder
    private var backgroundFill: some View {
        switch state {
        case .idle:
            LinearGradient(
                colors: [.white.opacity(0.08), .white.opacity(0.03)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .selected:
            LinearGradient(
                colors: [AppColors.Default.goldPrimary.opacity(0.22),
                         AppColors.Default.goldPrimary.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .correct:
            LinearGradient(
                colors: [AppColors.Default.success.opacity(0.40),
                         AppColors.Default.success.opacity(0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .wrong:
            LinearGradient(
                colors: [AppColors.Default.error.opacity(0.40),
                         AppColors.Default.error.opacity(0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .disabled:
            Color.white.opacity(0.02)
        }
    }

    var body: some View {
        Button(action: {
            guard state == .idle else { return }
            onTap()
        }) {
            HStack(spacing: AppSizes.Spacing.sm) {
                // الحرف
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.55), accentColor.opacity(0.25)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Circle()
                        .stroke(accentColor.opacity(0.7), lineWidth: 1.5)
                    Text(letter)
                        .font(.poppins(.black, size: 18))
                        .foregroundStyle(state == .disabled ? .white.opacity(0.2) : .white)
                }
                .frame(width: 38, height: 38)
                .shadow(color: state == .selected || state == .correct
                        ? accentColor.opacity(0.5) : .clear, radius: 6)

                // النص
                Text(text)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(state == .disabled ? .white.opacity(0.2) : .white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // علامة النتيجة
                Group {
                    switch state {
                    case .correct: Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(AppColors.Default.success)
                    case .wrong:   Image(systemName: "xmark.octagon.fill")
                            .foregroundStyle(AppColors.Default.error)
                    default: EmptyView()
                    }
                }
                .font(.system(size: 22))
                .transition(.scale.combined(with: .opacity))
            }
            .padding(AppSizes.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(backgroundFill)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(accentColor, lineWidth: state == .idle ? 1 : 2)
            )
            .shadow(color: state == .correct ? AppColors.Default.success.opacity(0.4) : .clear, radius: 10)
            .opacity(state == .disabled ? 0.45 : 1)
            .scaleEffect(state == .correct ? 1.03 : 1.0)
        }
        .disabled(state != .idle)
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state)
    }
}

private extension Array {
    subscript(safe idx: Int) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}

// MARK: - ساحة اللاعبين (1 ضد 1 أو 4 لاعبين)
struct PlayersBattlefield: View {
    let me: MatchPlayer
    let opponents: [MatchPlayer]
    let eliminatedIds: Set<String>
    let myShaking: Bool
    let shakingOpponentId: String?
    let attackAnimating: Bool
    let attackTargetId: String?
    var myShieldActive: Bool = false
    var phase: MatchPhase = .battle      // ✨ يحدّد عرض HP أو "قوة"
    var answeredUserIds: Set<String> = []  // ✨ من جاوب على السؤال الحالي
    var showAnsweredStatus: Bool = false    // ✨ هل أظهر "جاوب/يكتب"؟
    var myStreakActive: Bool = false        // 🔥 لو في streak ≥3 لي

    private var isCollectionPhase: Bool { phase == .collection }

    /// مَن يقود السكور؟ (لـ crown)
    private var leaderId: String? {
        let allPlayers = [me] + opponents
        guard let max = allPlayers.max(by: { $0.score < $1.score }) else { return nil }
        // إذا تعادل، لا تاج
        let topScore = max.score
        let topCount = allPlayers.filter { $0.score == topScore }.count
        guard topCount == 1, topScore > 0 else { return nil }
        return max.id
    }

    var body: some View {
        if opponents.count == 1 {
            oneVsOneLayout
        } else {
            fourPlayerLayout
        }
    }

    // MARK: - 1v1 — قلعتين كبيرتين
    private var oneVsOneLayout: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            castleCard(
                player: me, castle: .player,
                hpColor: .green, isShaking: myShaking, isMine: true,
                isEliminated: eliminatedIds.contains(me.id),
                compact: false
            )
            vsIndicator
            castleCard(
                player: opponents[0], castle: .enemy,
                hpColor: .red,
                isShaking: shakingOpponentId == opponents[0].id,
                isMine: false,
                isEliminated: eliminatedIds.contains(opponents[0].id),
                compact: false
            )
        }
    }

    // MARK: - 4 لاعبين — Grid مدمج
    private var fourPlayerLayout: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            // أنا (أعلى)
            HStack {
                Spacer()
                castleCard(
                    player: me, castle: .player,
                    hpColor: .green, isShaking: myShaking, isMine: true,
                    isEliminated: eliminatedIds.contains(me.id),
                    compact: true
                )
                Spacer()
            }

            // الخصوم (صف أفقي)
            HStack(spacing: AppSizes.Spacing.xs) {
                ForEach(opponents, id: \.id) { opp in
                    castleCard(
                        player: opp, castle: .enemy,
                        hpColor: .red,
                        isShaking: shakingOpponentId == opp.id,
                        isMine: false,
                        isEliminated: eliminatedIds.contains(opp.id),
                        compact: true
                    )
                }
            }
        }
    }

    // MARK: - Card اللاعب
    private func castleCard(
        player: MatchPlayer,
        castle: CastleSide,
        hpColor: Color,
        isShaking: Bool,
        isMine: Bool,
        isEliminated: Bool,
        compact: Bool
    ) -> some View {
        let isLeader = (leaderId == player.id)
        let castleSize: CGFloat = compact ? 58 : 90
        let nameSize: CGFloat = compact ? 10 : 11

        return VStack(spacing: compact ? 3 : 6) {
            // الاسم + Level badge
            HStack(spacing: 4) {
                AvatarView(imageURL: player.avatarUrl, size: compact ? 18 : 22)
                Text(isMine ? "أنت" : player.username)
                    .font(.cairo(.bold, size: nameSize))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let lvl = player.level {
                    Text("Lv.\(lvl)")
                        .font(.poppins(.bold, size: 8))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(isMine ? AppColors.Default.goldPrimary : Color(hex: "F87171"))
                        .clipShape(Capsule())
                }
            }

            // 👑 Crown إذا هذا اللاعب هو القائد
            if isLeader {
                LeaderCrown(isLeader: true)
                    .frame(height: 14)
                    .padding(.bottom, -2)
            }

            // النقاط مع flash + streak ring
            ScoreBadge(
                score: player.score,
                color: isMine ? AppColors.Default.goldPrimary : Color(hex: "F87171"),
                compact: compact,
                streakActive: isMine && myStreakActive   // streak فقط للاعبي
            )

            // hpPercentage 0-100 (للطبقات): نسبة hp/maxHp ×100
            let hpRatio: Double = (player.maxHp > 0) ? Double(player.hp) / Double(player.maxHp) : 1.0
            let hpStage: Int = isCollectionPhase ? 100 : Int(hpRatio * 100)

            // ✨ القلعة تنمو في Phase 1 مع تجميع القوة (1.0 → 1.15 على مدى 0..10 power)
            let growthScale: CGFloat = isCollectionPhase
                ? 1.0 + min(CGFloat(player.score) * 0.012, 0.15)
                : 1.0

            CastleView(
                side: castle,
                hpPercentage: hpStage,
                isShaking: isShaking,
                shieldActive: isMine && myShieldActive
            )
            .frame(width: castleSize, height: castleSize)
            .scaleEffect(growthScale)
            .animation(.spring(response: 0.5, dampingFraction: 0.65), value: player.score)

            if isCollectionPhase {
                powerCapsule(score: player.score, isMine: isMine, compact: compact)
            } else {
                CastleHPBar(percent: hpRatio, color: hpColor)
                    .frame(width: castleSize)

                if !compact {
                    Text("\(player.hp)/\(max(player.maxHp, 1)) HP")
                        .font(.poppins(.bold, size: 10))
                        .foregroundStyle(hpColor)
                        .monospacedDigit()
                }
            }

            if isEliminated {
                Text("خرج")
                    .font(.cairo(.bold, size: 9))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(Color.red.opacity(0.7))
                    .clipShape(Capsule())
            }

            // ✨ مؤشّر "جاوب/يكتب" للخصم فقط
            if !isMine && showAnsweredStatus {
                OpponentStatusBadge(hasAnswered: answeredUserIds.contains(player.id))
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity)
        .grayscale(isEliminated ? 1 : 0)
        .opacity(isEliminated ? 0.5 : 1)
    }

    // MARK: - Power capsule (Phase 1)
    @ViewBuilder
    private func powerCapsule(score: Int, isMine: Bool, compact: Bool) -> some View {
        let accent = isMine ? Color(hex: "60A5FA") : Color(hex: "F87171")
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: compact ? 8 : 10, weight: .black))
                .foregroundStyle(accent)
            Text("\(score)")
                .font(.poppins(.black, size: compact ? 11 : 13))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("قوة")
                .font(.cairo(.bold, size: compact ? 9 : 10))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, compact ? 8 : 10).padding(.vertical, compact ? 3 : 4)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.20), accent.opacity(0.08)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(accent.opacity(0.5), lineWidth: 1))
        .shadow(color: accent.opacity(0.3), radius: 4)
    }

    @ViewBuilder
    private var vsIndicator: some View {
        VSIndicatorView(attackAnimating: attackAnimating)
            .frame(width: 60)
    }
}

// MARK: - VS متحرّك مع حلقة ذهبية + لمعان
struct VSIndicatorView: View {
    var attackAnimating: Bool

    @State private var rotation: Double = 0
    @State private var glow: Bool = false

    var body: some View {
        ZStack {
            // حلقة ذهبية تدور
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFE55C"),
                            Color(hex: "FFD700"),
                            Color(hex: "DAA520").opacity(0.3)
                        ],
                        startPoint: .top, endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color(hex: "FFD700").opacity(glow ? 0.6 : 0.2), radius: 8)

            // النص VS
            Text("VS")
                .font(.poppins(.black, size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: glow ? 8 : 3)

            // أنيميشن القذيفة (من اليمين لليسار)
            if attackAnimating {
                CombatEffect.cannonball.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .offset(x: attackAnimating ? -60 : 60)
                    .rotationEffect(.degrees(attackAnimating ? -720 : 0))
                    .animation(.easeIn(duration: 0.6), value: attackAnimating)
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - شريط العناصر (Inventory)
struct InventoryBar: View {
    let inventory: [PowerUpIcon: Int]
    let onUse: (PowerUpIcon) -> Void
    let disabled: Bool

    @State private var tooltipFor: PowerUpIcon? = nil

    // الترتيب المفضّل
    private let order: [PowerUpIcon] = [.shield, .revealAnswer, .bird, .hint, .fiftyFifty, .freeze, .skip, .thunder]

    var body: some View {
        VStack(spacing: 6) {
            // tooltip
            if let tip = tooltipFor {
                HStack(spacing: 6) {
                    Image(systemName: tip.sfSymbol ?? "info.circle")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tip.titleAr)
                            .font(.cairo(.bold, size: 11))
                            .foregroundStyle(.white)
                        Text(tip.descriptionAr)
                            .font(.cairo(.medium, size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1)
                )
                .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
            }

            HStack(spacing: AppSizes.Spacing.xs) {
                ForEach(order) { power in
                    let count = inventory[power] ?? 0
                    powerUpButton(power: power, count: count)
                }
            }
            .padding(AppSizes.Spacing.sm)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: tooltipFor)
    }

    private func powerUpButton(power: PowerUpIcon, count: Int) -> some View {
        Button {
            guard !disabled, count > 0 else { return }
            onUse(power)
        } label: {
            powerUpLabel(power: power, count: count)
        }
        .disabled(disabled || count == 0)
        .frame(maxWidth: .infinity)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    HapticManager.light()
                    tooltipFor = power
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if tooltipFor == power { tooltipFor = nil }
                    }
                }
        )
    }

    private func powerUpLabel(power: PowerUpIcon, count: Int) -> some View {
        Group {
            ZStack(alignment: .topLeading) {
                Group {
                    if power.sfSymbol != nil {
                        // SF Symbol fallback (للعصفور وغيره)
                        power.iconView
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFE55C"), Color(hex: "FFB800")],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 42, height: 42)
                    } else {
                        power.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42, height: 42)
                    }
                }
                .opacity(count > 0 && !disabled ? 1 : 0.45)
                .grayscale(count > 0 && !disabled ? 0 : 0.6)

                if count > 0 {
                    Text("\(count)")
                        .font(.poppins(.bold, size: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(AppColors.Default.goldPrimary)
                        .clipShape(Capsule())
                        .offset(x: -4, y: -2)
                }
            }
        }
    }
}

// MARK: - شريط المؤقّت + التقدّم
struct MatchHeader: View {
    let questionIndex: Int
    let totalQuestions: Int
    let timeRemaining: Int
    let timeLimit: Int
    let onClose: () -> Void

    private var progress: Double {
        guard timeLimit > 0 else { return 0 }
        return Double(timeRemaining) / Double(timeLimit)
    }

    private var timerColor: Color {
        if timeRemaining <= 5 { return .red }
        if timeRemaining <= 10 { return .orange }
        return AppColors.Default.goldPrimary
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: AppSizes.Spacing.md) {
                Button {
                    HapticManager.light()
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // التقدّم
                Text("\(questionIndex)/\(totalQuestions)")
                    .font(.poppins(.bold, size: 13))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // المؤقت مع pulse عند الحرج
                TimerChip(timeRemaining: timeRemaining, color: timerColor, timeLimit: timeLimit)
            }

            // شريط تقدّم الوقت
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [timerColor.opacity(0.7), timerColor],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .shadow(color: timerColor.opacity(0.5), radius: 3)
                }
            }
            .frame(height: 4)
            .animation(.linear(duration: 0.3), value: progress)
        }
    }
}
