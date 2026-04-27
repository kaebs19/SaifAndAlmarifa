//
//  InputAnswerView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Components/InputAnswerView.swift
//  حقل إدخال إجابة — للأسئلة من نوع input
//  numericInput  → لوحة مفاتيح رقمية مخصّصة (NumericKeypadView)
//  textInput     → TextField + لوحة النظام
//

import SwiftUI

struct InputAnswerView: View {
    let question: MatchQuestion
    @Binding var answer: String
    let isSubmitted: Bool
    let isRevealing: Bool
    let result: AnswerResult?
    let onSubmit: () -> Void
    var wrongShakeNonce: Int = 0     // ✨ trigger الاهتزاز
    var pointsBurstNonce: Int = 0    // ✨ trigger الـ sparkle

    @FocusState private var isFocused: Bool

    private var isNumeric: Bool { question.answerType == .numericInput }

    private var stateColor: Color {
        if isRevealing, let r = result {
            if r.isCorrect { return AppColors.Default.success }
            if r.isClosest { return Color(hex: "F59E0B") }
            return AppColors.Default.error
        }
        if isSubmitted { return AppColors.Default.goldPrimary }
        return .white.opacity(0.2)
    }

    var body: some View {
        VStack(spacing: AppSizes.Spacing.sm) {   // أنعم — أقل ارتفاع
            if isRevealing, let r = result {
                // 🎯 الكشف الكبير — يستبدل الـ keypad/textfield
                bigRevealCard(correct: question.correctAnswer ?? "", result: r)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .shake(triggeredBy: wrongShakeNonce)   // ✨ اهتزاز عند الخطأ
            } else if isNumeric {
                numericModeBody
            } else {
                textModeBody
            }

            // حالة "تم الإرسال" (مشتركة)
            if isSubmitted && !isRevealing {
                HStack(spacing: 6) {
                    ProgressView().tint(AppColors.Default.goldPrimary).scaleEffect(0.7)
                    Text("تم الإرسال — في انتظار الخصم...")
                        .font(.cairo(.medium, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isRevealing)
        .onAppear {
            if !isNumeric {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if !isSubmitted { isFocused = true }
                }
            }
        }
        .onChange(of: isSubmitted) { _, new in
            if new { isFocused = false }
        }
    }

    // MARK: - Numeric mode (keypad)
    @ViewBuilder
    private var numericModeBody: some View {
        VStack(spacing: 8) {
            // شاشة العرض
            numericDisplay

            // لوحة المفاتيح
            NumericKeypadView(
                value: $answer,
                isDisabled: isSubmitted || isRevealing,
                canSubmit: !answer.isEmpty,
                onSubmit: onSubmit
            )
        }
    }

    private var numericDisplay: some View {
        ZStack {
            // خلفية
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.10), .white.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [stateColor, stateColor.opacity(0.4)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 2
                )

            HStack(spacing: 10) {
                Image(systemName: "number")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(stateColor.opacity(0.6))

                if answer.isEmpty {
                    Text("اكتب الرقم")
                        .font(.cairo(.bold, size: 14))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    Text(answer)
                        .font(.poppins(.black, size: 26))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, AppSizes.Spacing.md)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 50)
        .shadow(color: stateColor.opacity(0.25), radius: 6)
    }

    // MARK: - Text mode (system keyboard)
    @ViewBuilder
    private var textModeBody: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Image(systemName: "character.cursor.ibeam")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(stateColor.opacity(0.7))
                .frame(width: 24)

            TextField("اكتب إجابتك...", text: $answer)
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(.white)
                .tint(AppColors.Default.goldPrimary)
                .keyboardType(.default)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit { if !isSubmitted { onSubmit() } }
                .disabled(isSubmitted || isRevealing)
                .multilineTextAlignment(.center)

            if !answer.isEmpty && !isSubmitted {
                Button { answer = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(AppSizes.Spacing.md)
        .background(
            LinearGradient(
                colors: [.white.opacity(0.10), .white.opacity(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(
                    LinearGradient(
                        colors: [stateColor, stateColor.opacity(0.5)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: stateColor.opacity(isFocused ? 0.35 : 0), radius: 8)

        // زر الإرسال (للوضع النصي فقط)
        if !isSubmitted && !isRevealing {
            Button {
                HapticManager.light()
                onSubmit()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("إرسال الإجابة")
                }
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(answer.isEmpty ? .white.opacity(0.4) : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSizes.Spacing.sm)
                .background(submitBackground)
                .clipShape(Capsule())
            }
            .disabled(answer.isEmpty)
        }
    }

    // MARK: - Big Reveal Card (يستبدل الـ keypad أثناء الكشف)
    private func bigRevealCard(correct: String, result r: AnswerResult) -> some View {
        let isCorrect = r.isCorrect
        let isClosest = r.isClosest
        let isFastest = r.isFastest
        let pts = r.pointsAwarded

        let accent: Color = isCorrect
            ? AppColors.Default.success
            : (isClosest ? Color(hex: "F59E0B") : AppColors.Default.error)

        let iconName: String = isCorrect
            ? "checkmark.seal.fill"
            : (isClosest ? "scope" : "xmark.octagon.fill")

        // عنوان من backend feedback أو fallback محلي
        let title: String = r.feedback ?? (isCorrect
            ? (isFastest ? "✓ صحيح + الأسرع!" : "✓ صحيح!")
            : (isClosest ? "🎯 الأقرب" : "❌ خطأ"))

        return VStack(spacing: 14) {
            // الأيقونة الكبيرة
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.4), accent.opacity(0.15)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(accent.opacity(0.6), lineWidth: 2)
                    .frame(width: 72, height: 72)
                Image(systemName: iconName)
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(accent)
            }
            .shadow(color: accent.opacity(0.5), radius: 14)

            // العنوان
            Text(title)
                .font(.cairo(.black, size: AppSizes.Font.title3))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // إجابتي vs الصحيحة
            HStack(spacing: AppSizes.Spacing.lg) {
                valueColumn(label: "إجابتك", value: r.submittedValue.isEmpty ? "—" : r.submittedValue,
                            color: isCorrect ? AppColors.Default.success : .white.opacity(0.7))
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                valueColumn(label: "الصحيحة", value: correct,
                            color: AppColors.Default.success)
            }

            // ✨ Stats row (الزمن + الفرق) — يظهر إذا أرسل backend الأوقات
            if r.timeMs != nil || r.opponentTimeMs != nil {
                statsRow(myMs: r.timeMs, oppMs: r.opponentTimeMs)
                    .transition(.opacity)
            }

            // chips النقاط مع Sparkle burst
            if pts > 0 {
                ZStack {
                    SparkleBurst(nonce: pointsBurstNonce, color: Color(hex: "FFD700"))
                        .frame(width: 1, height: 1)
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("+\(pts) قوة")
                            .font(.poppins(.black, size: 18))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFB800")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: 8)
                }
            }
        }
        .padding(.vertical, AppSizes.Spacing.lg)
        .padding(.horizontal, AppSizes.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                LinearGradient(
                    colors: [accent.opacity(0.18), accent.opacity(0.06)],
                    startPoint: .top, endPoint: .bottom
                )
                .background(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(accent.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: accent.opacity(0.3), radius: 12)
    }

    private func statsRow(myMs: Int?, oppMs: Int?) -> some View {
        HStack(spacing: 12) {
            if let m = myMs {
                statChip(label: "أنت", value: formatTime(m), tint: AppColors.Default.goldPrimary)
            }
            if let o = oppMs {
                statChip(label: "الخصم", value: formatTime(o), tint: Color(hex: "F87171"))
            }
            if let m = myMs, let o = oppMs {
                let diff = abs(m - o)
                let sign = m < o ? "-" : "+"
                statChip(label: "الفرق", value: "\(sign)\(formatTime(diff))",
                         tint: m < o ? AppColors.Default.success : .white.opacity(0.4))
            }
        }
        .padding(.top, 4)
    }

    private func statChip(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.cairo(.medium, size: 10))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.poppins(.bold, size: 13))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatTime(_ ms: Int) -> String {
        if ms >= 10_000 { return "\(ms/1000)s" }
        let secs = Double(ms) / 1000.0
        return String(format: "%.1fs", secs)
    }

    private func valueColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.cairo(.medium, size: 11))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.poppins(.black, size: 24))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    @ViewBuilder
    private var submitBackground: some View {
        if answer.isEmpty {
            Color.gray.opacity(0.2)
        } else {
            LinearGradient(
                colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }
}
