//
//  TutorialOverlay.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/TutorialOverlay.swift
//  Tutorial overlay يظهر مرّة واحدة في أول مباراة Castle Siege
//

import SwiftUI

struct CastleSiegeTutorialOverlay: View {
    @Binding var isVisible: Bool
    @State private var step: Int = 0

    private let steps: [TutorialStep] = [
        TutorialStep(
            icon: "shield.lefthalf.filled",
            iconColor: Color(hex: "60A5FA"),
            title: "المرحلة الأولى — تجميع القوة",
            text: "4 أسئلة بإجابات رقمية. الأسرع + الأقرب = قوة أكثر لقلعتك."
        ),
        TutorialStep(
            icon: "bolt.fill",
            iconColor: Color(hex: "FFB800"),
            title: "نظام النقاط",
            text: "صحيح + الأسرع = +3 قوة\nصحيح فقط = +2\nأقرب من بين الخاطئين = +1"
        ),
        TutorialStep(
            icon: "swords.fill",
            iconColor: Color(hex: "EF4444"),
            title: "المرحلة الثانية — المعركة",
            text: "10 أسئلة. أول من يجيب صح يضرب قلعة الخصم -1 HP. يفوز من يهدم القلعة أولاً."
        ),
        TutorialStep(
            icon: "number",
            iconColor: AppColors.Default.goldPrimary,
            title: "لوحة المفاتيح",
            text: "اكتب الرقم بلوحة المفاتيح المخصّصة. ضغطة طويلة على ⌫ تمسح الكل."
        )
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { } // امنع التسرّب

            VStack(spacing: AppSizes.Spacing.lg) {
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? AppColors.Default.goldPrimary : .white.opacity(0.2))
                            .frame(width: i == step ? 22 : 8, height: 6)
                            .animation(.spring(response: 0.3), value: step)
                    }
                }
                .padding(.top, 32)

                Spacer()

                // المحتوى
                stepContent(steps[step])
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer()

                // الأزرار
                HStack(spacing: 12) {
                    if step > 0 {
                        Button {
                            HapticManager.light()
                            withAnimation(.easeInOut(duration: 0.3)) { step -= 1 }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 44)
                                .background(.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button {
                        HapticManager.medium()
                        if step < steps.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) { step += 1 }
                        } else {
                            withAnimation(.easeInOut) { isVisible = false }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(step < steps.count - 1 ? "التالي" : "ابدأ اللعب")
                            Image(systemName: step < steps.count - 1
                                  ? "chevron.left"
                                  : "play.fill")
                        }
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 10)
                    }
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.bottom, 30)
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private func stepContent(_ s: TutorialStep) -> some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [s.iconColor.opacity(0.35), s.iconColor.opacity(0.10)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(s.iconColor.opacity(0.6), lineWidth: 2)
                    .frame(width: 110, height: 110)
                Image(systemName: s.icon)
                    .font(.system(size: 50, weight: .black))
                    .foregroundStyle(s.iconColor)
            }
            .shadow(color: s.iconColor.opacity(0.4), radius: 18)

            Text(s.title)
                .font(.cairo(.black, size: AppSizes.Font.title2))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(s.text)
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSizes.Spacing.lg)
                .lineSpacing(4)
        }
    }
}

private struct TutorialStep {
    let icon: String
    let iconColor: Color
    let title: String
    let text: String
}
