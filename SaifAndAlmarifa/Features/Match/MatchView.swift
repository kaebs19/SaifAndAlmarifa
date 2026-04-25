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
                    myShieldActive: viewModel.activePowerUps.contains(.shield)
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

                // شريط العناصر
                InventoryBar(
                    inventory: viewModel.inventory,
                    onUse: { viewModel.usePowerUp($0) },
                    disabled: viewModel.selectedAnswerIndex != nil || viewModel.isRevealing
                )
                .padding(AppSizes.Spacing.lg)
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

            // تلميح
            if let hint = viewModel.hintMessage {
                hintBanner(hint).zIndex(6)
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

    // MARK: - Background
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "08091E"), Color(hex: "12103B"), Color(hex: "0B0A24")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // هالات خلف القلعتين
            GeometryReader { geo in
                Circle()
                    .fill(AppColors.Default.goldPrimary.opacity(0.08))
                    .frame(width: 240, height: 240)
                    .blur(radius: 80)
                    .offset(x: -geo.size.width * 0.4, y: -geo.size.height * 0.2)

                Circle()
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 240, height: 240)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.2)
            }
            .ignoresSafeArea()

            // جزيئات ذهبية عائمة
            FloatingEmbers()
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
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
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.cairo(.regular, size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(AppSizes.Spacing.sm)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(color.opacity(0.2), lineWidth: 1)
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
                    onSubmit: { viewModel.submitAnswer() }
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

    // MARK: - Freeze Overlay
    private var frozenOverlay: some View {
        ZStack {
            Color(hex: "60A5FA").opacity(0.15).ignoresSafeArea()
            VStack {
                Image(systemName: "snowflake")
                    .font(.system(size: 80))
                    .foregroundStyle(Color(hex: "93C5FD"))
                    .shadow(color: Color(hex: "60A5FA"), radius: 20)
                Text("مُجمَّد!")
                    .font(.cairo(.black, size: AppSizes.Font.title1))
                    .foregroundStyle(.white)
            }
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
