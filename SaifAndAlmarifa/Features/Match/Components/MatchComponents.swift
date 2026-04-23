//
//  MatchComponents.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Components/MatchComponents.swift
//  مكوّنات UI لشاشة المباراة

import SwiftUI

// MARK: - Timer Chip مع pulse حرج
struct TimerChip: View {
    let timeRemaining: Int
    let color: Color

    @State private var pulse: Bool = false

    private var isUrgent: Bool { timeRemaining <= 5 }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 11))
            Text("\(timeRemaining)")
                .font(.poppins(.black, size: 16))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
        .scaleEffect(isUrgent && pulse ? 1.18 : 1.0)
        .shadow(color: isUrgent ? color.opacity(0.6) : .clear, radius: isUrgent ? 8 : 0)
        .onChange(of: timeRemaining) { _, _ in
            // كل ثانية في الوضع الحرج، pulse
            if isUrgent {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { pulse = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { pulse = false }
                }
            }
        }
    }
}

// MARK: - ScoreBadge — يومض عند التغيير
struct ScoreBadge: View {
    let score: Int
    let color: Color
    var compact: Bool = false

    @State private var lastScore: Int = 0
    @State private var flash: Bool = false

    private var size: CGFloat { compact ? 14 : 20 }

    var body: some View {
        Text("\(score)")
            .font(.poppins(.black, size: size))
            .foregroundStyle(flash ? Color.green : color)
            .scaleEffect(flash ? 1.3 : 1.0)
            .shadow(color: flash ? Color.green.opacity(0.8) : .clear, radius: 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: flash)
            .onChange(of: score) { old, new in
                guard new > old else { return }
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

    private var bgColor: Color {
        switch state {
        case .idle:     return Color.white.opacity(0.06)
        case .selected: return AppColors.Default.goldPrimary.opacity(0.25)
        case .correct:  return AppColors.Default.success.opacity(0.35)
        case .wrong:    return AppColors.Default.error.opacity(0.35)
        case .disabled: return Color.white.opacity(0.02)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:     return .white.opacity(0.12)
        case .selected: return AppColors.Default.goldPrimary
        case .correct:  return AppColors.Default.success
        case .wrong:    return AppColors.Default.error
        case .disabled: return .white.opacity(0.05)
        }
    }

    var body: some View {
        Button(action: {
            guard state == .idle else { return }
            onTap()
        }) {
            HStack(spacing: AppSizes.Spacing.sm) {
                // الحرف
                Text(letter)
                    .font(.poppins(.black, size: 18))
                    .foregroundStyle(state == .disabled ? .white.opacity(0.2) : .white)
                    .frame(width: 36, height: 36)
                    .background(borderColor.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(borderColor, lineWidth: 1.5))

                // النص
                Text(text)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(state == .disabled ? .white.opacity(0.2) : .white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // علامة النتيجة
                Group {
                    switch state {
                    case .correct: Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColors.Default.success)
                    case .wrong:   Image(systemName: "xmark.circle.fill").foregroundStyle(AppColors.Default.error)
                    default: EmptyView()
                    }
                }
                .font(.system(size: 22))
            }
            .padding(AppSizes.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(borderColor, lineWidth: state == .idle ? 1 : 2)
            )
            .opacity(state == .disabled ? 0.5 : 1)
            .scaleEffect(state == .correct ? 1.03 : 1.0)
        }
        .disabled(state != .idle)
        .buttonStyle(ScaleButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: state)
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

            // النقاط مع flash animation
            ScoreBadge(score: player.score, color: isMine ? AppColors.Default.goldPrimary : Color(hex: "F87171"), compact: compact)

            CastleView(
                side: castle,
                hpPercentage: player.hp,
                isShaking: isShaking,
                shieldActive: isMine && myShieldActive
            )
            .frame(width: castleSize, height: castleSize)

            CastleHPBar(percent: Double(player.hp) / 100.0, color: hpColor)
                .frame(width: castleSize)

            if !compact {
                Text("\(player.hp) HP")
                    .font(.poppins(.bold, size: 10))
                    .foregroundStyle(hpColor)
            }

            if isEliminated {
                Text("خرج")
                    .font(.cairo(.bold, size: 9))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(Color.red.opacity(0.7))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .grayscale(isEliminated ? 1 : 0)
        .opacity(isEliminated ? 0.5 : 1)
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

    // الترتيب المفضّل
    private let order: [PowerUpIcon] = [.shield, .hint, .fiftyFifty, .freeze, .skip, .thunder]

    var body: some View {
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

    private func powerUpButton(power: PowerUpIcon, count: Int) -> some View {
        Button {
            guard !disabled, count > 0 else { return }
            onUse(power)
        } label: {
            ZStack(alignment: .topLeading) {
                power.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .opacity(count > 0 && !disabled ? 1 : 0.3)
                    .grayscale(count > 0 && !disabled ? 0 : 1)

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
        .disabled(disabled || count == 0)
        .frame(maxWidth: .infinity)
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
                TimerChip(timeRemaining: timeRemaining, color: timerColor)
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
