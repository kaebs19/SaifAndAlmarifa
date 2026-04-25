//
//  InputAnswerView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Components/InputAnswerView.swift
//  حقل إدخال إجابة — للأسئلة من نوع input

import SwiftUI

struct InputAnswerView: View {
    let question: MatchQuestion
    @Binding var answer: String
    let isSubmitted: Bool
    let isRevealing: Bool
    let result: AnswerResult?
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var keyboardType: UIKeyboardType {
        question.answerType.keyboardHint
    }

    private var stateColor: Color {
        if isRevealing, let r = result {
            if r.isCorrect { return AppColors.Default.success }
            if r.isClosest { return Color(hex: "F59E0B") }   // الأقرب لكن مش صحيح بالضبط
            return AppColors.Default.error
        }
        if isSubmitted { return AppColors.Default.goldPrimary }
        return .white.opacity(0.2)
    }

    var body: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // حقل الإدخال
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 18))
                    .foregroundStyle(stateColor.opacity(0.6))

                TextField("اكتب إجابتك...", text: $answer)
                    .font(.cairo(.bold, size: AppSizes.Font.title3))
                    .foregroundStyle(.white)
                    .tint(AppColors.Default.goldPrimary)
                    .keyboardType(keyboardType)
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
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(stateColor, lineWidth: 2)
            )

            // عرض الإجابة الصحيحة (بعد الكشف)
            if isRevealing, let correct = question.correctAnswer {
                revealCard(correct: correct)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // زر الإرسال
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
            } else if isSubmitted && !isRevealing {
                HStack(spacing: 6) {
                    ProgressView().tint(AppColors.Default.goldPrimary).scaleEffect(0.7)
                    Text("تم الإرسال — في انتظار الخصم...")
                        .font(.cairo(.medium, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !isSubmitted { isFocused = true }
            }
        }
        .onChange(of: isSubmitted) { _, new in
            if new { isFocused = false }
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
