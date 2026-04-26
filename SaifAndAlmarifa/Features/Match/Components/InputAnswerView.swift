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
        VStack(spacing: AppSizes.Spacing.md) {
            if isNumeric {
                numericModeBody
            } else {
                textModeBody
            }

            // Reveal card
            if isRevealing, let correct = question.correctAnswer {
                revealCard(correct: correct)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        VStack(spacing: AppSizes.Spacing.sm) {
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

            HStack(spacing: 12) {
                Image(systemName: "number")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(stateColor.opacity(0.6))

                if answer.isEmpty {
                    Text("اكتب الرقم")
                        .font(.cairo(.medium, size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                } else {
                    Text(answer)
                        .font(.poppins(.black, size: 32))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, AppSizes.Spacing.md)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 64)
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

    // MARK: - Reveal Card
    private func revealCard(correct: String) -> some View {
        VStack(spacing: 6) {
            Text("الإجابة الصحيحة")
                .font(.cairo(.medium, size: 11))
                .foregroundStyle(.white.opacity(0.5))
            Text(correct)
                .font(.cairo(.black, size: 22))
                .foregroundStyle(AppColors.Default.success)

            if let r = result {
                HStack(spacing: 8) {
                    if r.isFastest {
                        chipBadge("⚡ الأسرع", color: Color(hex: "60A5FA"))
                    }
                    if r.isClosest {
                        chipBadge("🎯 الأقرب", color: Color(hex: "F59E0B"))
                    }
                    if r.pointsAwarded > 0 {
                        chipBadge("+\(r.pointsAwarded) قوة", color: AppColors.Default.success)
                    }
                }
            }
        }
        .padding(AppSizes.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColors.Default.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(AppColors.Default.success.opacity(0.3), lineWidth: 1)
        )
    }

    private func chipBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.cairo(.bold, size: 11))
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
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
