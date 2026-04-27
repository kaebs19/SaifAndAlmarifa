//
//  MatchView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/MatchView.swift
//  الشاشة الأساسية للمباراة — Castle Battle

import SwiftUI

struct MatchView: View {

    @StateObject private var viewModel: MatchViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showExitConfirm = false

    init(matchId: String, opponents: [MatchPlayer]) {
        _viewModel = StateObject(wrappedValue: MatchViewModel(matchId: matchId, opponents: opponents))
    }

    /// Convenience للتوافق مع 1v1
    init(matchId: String, opponent: MatchPlayer) {
        self.init(matchId: matchId, opponents: [opponent])
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                MatchHeader(
                    questionIndex: viewModel.currentQuestion?.index ?? 0,
                    totalQuestions: viewModel.currentQuestion?.total ?? 10,
                    timeRemaining: viewModel.timeRemaining,
                    timeLimit: viewModel.currentQuestion?.timeLimit ?? 15,
                    onClose: { showExitConfirm = true }
                )
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.top, AppSizes.Spacing.md)

                // البانر العلوي (قلاع + HP + نقاط) — يدعم 1v1 و 4p
                PlayersBattlefield(
                    me: viewModel.me,
                    opponents: viewModel.opponents,
                    eliminatedIds: viewModel.eliminatedIds,
                    myShaking: viewModel.myCastleShaking,
                    shakingOpponentId: viewModel.shakingOpponentId,
                    attackAnimating: viewModel.attackAnimating,
                    attackTargetId: viewModel.attackTargetId,
                    myShieldActive: viewModel.activePowerUps.contains(.shield),
                    phase: viewModel.currentPhase,
                    answeredUserIds: viewModel.answeredUserIds,
                    showAnsweredStatus: viewModel.currentQuestion != nil
                                          && !viewModel.isRevealing
                                          && viewModel.hasSubmitted
                )
                .padding(.horizontal, AppSizes.Spacing.sm)
                .padding(.top, AppSizes.Spacing.sm)

                // مؤشر المرحلة
                phaseIndicator
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.top, AppSizes.Spacing.sm)

                // بطاقة السؤال + الإجابات
                if let q = viewModel.currentQuestion {
                    questionAndAnswers(q)
                        .padding(.horizontal, AppSizes.Spacing.lg)
                        .padding(.top, AppSizes.Spacing.md)
                } else {
                    waitingForQuestion
                        .padding(.top, AppSizes.Spacing.md)
                }

                Spacer()

                // شريط العناصر — متاح فقط في 4-player MCQ (مخفي في Castle Siege 1v1)
                if !viewModel.isOneVsOne {
                    InventoryBar(
                        inventory: viewModel.inventory,
                        onUse: { viewModel.usePowerUp($0) },
                        disabled: viewModel.hasSubmitted || viewModel.isRevealing
                    )
                    .padding(AppSizes.Spacing.lg)
                    .transition(.opacity)
                }
            }

            // شاشة Phase Transition (بين المراحل)
            if viewModel.showPhaseTransition, let result = viewModel.phaseResult {
                PhaseTransitionView(
                    me: viewModel.me,
                    opponents: viewModel.opponents,
                    powers: result.powers
                )
                .transition(.opacity)
                .zIndex(8)
            }

            // شاشة النهاية
            if let result = viewModel.matchResult {
                MatchEndView(
                    result: result,
                    history: viewModel.questionHistory,
                    onRematch: viewModel.rematchStatus == .waitingForOpponent
                        ? nil   // معطّل مؤقتاً بانتظار الخصم
                        : { viewModel.requestRematch() },
                    onClose: { dismiss() }
                )
                .overlay(alignment: .top) {
                    if viewModel.rematchStatus == .waitingForOpponent {
                        rematchWaitingBanner
                            .padding(.top, 80)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else if viewModel.rematchStatus == .opponentOffered {
                        rematchOfferedBanner
                            .padding(.top, 80)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }

            // تأثير التجميد
            if viewModel.isFrozen {
                frozenOverlay.zIndex(5)
            }

            // ✨ HP حرج — حواف نابضة
            if viewModel.isCriticalHP {
                CriticalHPOverlay().zIndex(4)
            }

            // ✨ Combo banner
            if viewModel.showCombo && viewModel.streak >= 2 {
                ComboBanner(count: viewModel.streak).zIndex(7)
            }

            // تلميح
            if let hint = viewModel.hintMessage {
                hintBanner(hint).zIndex(6)
            }

            // 🐦 banner العصفور (مدى رقمي)
            if let range = viewModel.rangeHint {
                rangeHintBanner(min: range.min, max: range.max).zIndex(6)
            }

            // Pre-match countdown (3-2-1 قبل أول سؤال)
            if let count = viewModel.preMatchCountdown {
                preMatchCountdownOverlay(count: count)
                    .zIndex(11)
            }
        }
        .task {
            viewModel.start()
        }
        .onDisappear { viewModel.onDisappear() }
        .confirmationDialog("هل تريد الخروج من المباراة؟", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("خروج", role: .destructive) { dismiss() }
            Button("استكمال", role: .cancel) {}
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.matchResult)
    }

    // MARK: - Background (ديناميكية حسب المرحلة)
    private var background: some View {
        ZStack {
            // الخلفية الأساسية تتغيّر حسب المرحلة
            backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.2), value: viewModel.currentPhase)

            // هالات خلف القلعتين
            GeometryReader { geo in
                Circle()
                    .fill(myCastleAura.opacity(0.10))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(x: -geo.size.width * 0.4, y: -geo.size.height * 0.2)

                Circle()
                    .fill(enemyCastleAura.opacity(0.10))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.2)
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.2), value: viewModel.currentPhase)

            // جزيئات ذهبية عائمة
            FloatingEmbers()
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var backgroundGradient: some View {
        switch viewModel.currentPhase {
        case .collection:
            // أزرق هادئ — مرحلة بناء القوة
            LinearGradient(
                colors: [Color(hex: "0A1230"), Color(hex: "10204B"), Color(hex: "0B1024")],
                startPoint: .top, endPoint: .bottom
            )
        case .battle:
            // أحمر داكن — مرحلة المعركة
            LinearGradient(
                colors: [Color(hex: "1A0810"), Color(hex: "2D0815"), Color(hex: "0E0610")],
                startPoint: .top, endPoint: .bottom
            )
        case .transition, .ended:
            LinearGradient(
                colors: [Color(hex: "08091E"), Color(hex: "12103B"), Color(hex: "0B0A24")],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var myCastleAura: Color {
        viewModel.currentPhase == .battle
            ? Color(hex: "10B981")     // أخضر — قوّتي
            : AppColors.Default.goldPrimary
    }

    private var enemyCastleAura: Color {
        viewModel.currentPhase == .battle
            ? Color(hex: "EF4444")     // أحمر — الخطر
            : Color(hex: "60A5FA")
    }

    // MARK: - مؤشّر المرحلة
    private var phaseIndicator: some View {
        Group {
            switch viewModel.currentPhase {
            case .collection:
                phaseChip(
                    icon: "shield.lefthalf.filled",
                    title: "المرحلة 1: تجميع القوة",
                    subtitle: "أجب الأسرع والأقرب لتربح قوة",
                    color: Color(hex: "60A5FA")
                )
            case .battle:
                phaseChip(
                    icon: "swords.fill",
                    title: "المرحلة 2: المواجهة",
                    subtitle: "كل إجابة صحيحة تهدم قلعة الخصم",
                    color: AppColors.Default.error
                )
            case .transition, .ended:
                EmptyView()
            }
        }
    }

    private func phaseChip(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.35), color.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .stroke(color.opacity(0.6), lineWidth: 1.5)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)
            .shadow(color: color.opacity(0.5), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.cairo(.regular, size: 10))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()

            // شارة المرحلة
            Text(title.contains("1") ? "I" : "II")
                .font(.poppins(.black, size: 12))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, AppSizes.Spacing.xs)
        .background(
            LinearGradient(
                colors: [color.opacity(0.12), color.opacity(0.04)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.45), color.opacity(0.15)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - السؤال + الإجابات
    private func questionAndAnswers(_ q: MatchQuestion) -> some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // بطاقة السؤال (مع parchment background)
            ZStack {
                UIBanner.scroll.image
                    .resizable()
                    .scaledToFit()
                    .opacity(0.18)
                    .frame(maxWidth: .infinity, maxHeight: 120)

                Text(q.text)
                    .font(.cairo(.bold, size: AppSizes.Font.title3))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSizes.Spacing.md)
                    .padding(.vertical, AppSizes.Spacing.md)
            }
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1.5)
            )

            // إجابة input أو 4 خيارات
            if q.isInput {
                InputAnswerView(
                    question: q,
                    answer: $viewModel.inputAnswer,
                    isSubmitted: viewModel.hasSubmitted,
                    isRevealing: viewModel.isRevealing,
                    result: viewModel.lastAnswerResult,
                    onSubmit: { viewModel.submitAnswer() },
                    wrongShakeNonce: viewModel.wrongShakeNonce,
                    pointsBurstNonce: viewModel.pointsBurstNonce
                )
            } else {
                VStack(spacing: AppSizes.Spacing.xs) {
                    ForEach(Array(q.options.enumerated()), id: \.offset) { idx, text in
                        AnswerButton(
                            index: idx,
                            text: text,
                            state: answerState(for: idx, q: q),
                            onTap: { viewModel.selectAnswer(idx) }
                        )
                    }
                }
            }
        }
    }

    private func answerState(for index: Int, q: MatchQuestion) -> AnswerButton.AnswerState {
        if q.disabledIndices.contains(index) { return .disabled }

        // ✨ كشف الإجابة (reveal_answer power-up) قبل ما يجاوب
        // إذا correctIndex معروف ولم يصل reveal الفعلي بعد، أظهر الصحيح كـ "selected"
        if !viewModel.isRevealing,
           viewModel.selectedAnswerIndex == nil,
           let correct = q.correctIndex,
           index == correct {
            return .selected
        }

        let selected = viewModel.selectedAnswerIndex
        guard selected != nil else { return .idle }

        if viewModel.isRevealing, let correct = q.correctIndex {
            if index == correct { return .correct }
            if index == selected { return .wrong }
            return .idle
        }
        if index == selected { return .selected }
        return .idle
    }

    // MARK: - Waiting (مع Skeleton للسؤال)
    private var waitingForQuestion: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // Skeleton لبطاقة السؤال
            VStack(spacing: 8) {
                SkeletonBox(width: 240, height: 16, cornerRadius: 4)
                SkeletonBox(width: 200, height: 16, cornerRadius: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSizes.Spacing.md)
            .frame(height: 110)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(AppColors.Default.goldPrimary.opacity(0.2), lineWidth: 1)
            )

            // Skeleton لـ 4 إجابات
            VStack(spacing: AppSizes.Spacing.xs) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        Circle().fill(.white.opacity(0.08)).frame(width: 36, height: 36).shimmer()
                        SkeletonBox(width: 180, height: 14)
                        Spacer()
                    }
                    .padding(AppSizes.Spacing.md)
                    .frame(height: 64)
                    .background(.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                }
            }

            // Indicator صغير
            HStack(spacing: 6) {
                ProgressView().tint(AppColors.Default.goldPrimary).scaleEffect(0.8)
                Text("في انتظار أول سؤال...")
                    .font(.cairo(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    // MARK: - Freeze Overlay (الخصم جمّدك)
    private var frozenOverlay: some View {
        ZStack {
            Color(hex: "60A5FA").opacity(0.18).ignoresSafeArea()
            // طبقة ثلج شبه شفّافة
            VStack(spacing: 12) {
                Image(systemName: "snowflake")
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "DBEAFE"), Color(hex: "93C5FD")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "60A5FA"), radius: 24)
                    .symbolEffect(.pulse, options: .repeating)

                Text("❄️ مُجمَّد!")
                    .font(.cairo(.black, size: AppSizes.Font.title1))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 6)

                Text("الخصم استخدم تجميد الوقت")
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.vertical, AppSizes.Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(Color(hex: "93C5FD").opacity(0.4), lineWidth: 1.5)
            )
        }
        .transition(.opacity)
    }

    // MARK: - Pre-Match Countdown
    private func preMatchCountdownOverlay(count: Int) -> some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: AppSizes.Spacing.md) {
                Text("استعد!")
                    .font(.cairo(.black, size: AppSizes.Font.title2))
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(count)")
                    .font(.poppins(.black, size: 160))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.8), radius: 30)
                    .id(count)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: count)
    }

    // MARK: - Rematch Banners
    private var rematchWaitingBanner: some View {
        HStack(spacing: 6) {
            ProgressView().tint(AppColors.Default.goldPrimary).scaleEffect(0.8)
            Text("في انتظار قبول \(viewModel.opponent.username)...")
                .font(.cairo(.medium, size: 11))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, AppSizes.Spacing.md).padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.5), lineWidth: 1))
    }

    private var rematchOfferedBanner: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundStyle(AppColors.Default.goldPrimary)
            Text("\(viewModel.opponent.username) يتحداك مرة أخرى!")
                .font(.cairo(.bold, size: 11))
                .foregroundStyle(.white)
            Button {
                viewModel.requestRematch()
            } label: {
                Text("قبول")
                    .font(.cairo(.bold, size: 11))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(AppColors.Default.goldPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppSizes.Spacing.md).padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.Default.goldPrimary, lineWidth: 1.5))
    }

    // MARK: - Range Hint Banner (العصفور)
    private func rangeHintBanner(min: Int, max: Int) -> some View {
        VStack {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 22, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(hex: "FFD700"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("🐦 العصفور يهمس...")
                        .font(.cairo(.bold, size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 6) {
                        Text("\(min)")
                            .font(.poppins(.black, size: 18))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFD700").opacity(0.7))
                        Text("\(max)")
                            .font(.poppins(.black, size: 18))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }
            }
            .padding(AppSizes.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFD700").opacity(0.18),
                             Color(hex: "FFB800").opacity(0.10)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(Color(hex: "FFD700").opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 12)
            .padding(AppSizes.Spacing.lg)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Hint Banner
    private func hintBanner(_ text: String) -> some View {
        VStack {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(text)
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(AppSizes.Spacing.md)
            .background(Color.yellow.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(.yellow.opacity(0.5), lineWidth: 1.5)
            )
            .padding(AppSizes.Spacing.lg)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
