//
//  SpinWheelView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 13/04/2026.
//

import SwiftUI

// MARK: - شاشة عجلة الحظ
struct SpinWheelView: View {

    @StateObject private var viewModel = SpinWheelViewModel()
    @StateObject private var adManager = AdManager.shared
    @State private var rotation: Double = 0
    @Environment(\.dismiss) private var dismiss

    // ألوان شرائح العجلة
    private let sliceColors: [Color] = [
        Color(hex: "FFD700"), Color(hex: "1A1147"),
        Color(hex: "DAA520"), Color(hex: "15193D"),
        Color(hex: "FFA500"), Color(hex: "1A1147"),
        Color(hex: "B8860B"), Color(hex: "15193D")
    ]

    var body: some View {
        ZStack {
            GradientBackground.main

            VStack(spacing: AppSizes.Spacing.lg) {
                header
                Spacer()
                wheelSection
                Spacer()
                spinButton
                extraSpinInfo
            }
            .padding(AppSizes.Spacing.lg)

            // نتيجة الدوران
            if viewModel.showResult {
                resultOverlay
            }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: الهيدر
    private var header: some View {
        ZStack {
            Text(AppStrings.Main.spinWheel)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - العجلة
    private var wheelSection: some View {
        ZStack {
            // هالة خلفية
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.Default.goldPrimary.opacity(0.15), .clear],
                        center: .center, startRadius: 50, endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)

            // العجلة
            ZStack {
                // الشرائح
                ForEach(0..<viewModel.slots.count, id: \.self) { i in
                    wheelSlice(index: i, total: viewModel.slots.count)
                }

                // الحلقة الخارجية
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "B8860B"), Color(hex: "FFD700")],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 4
                    )

                // الوسط
                Circle()
                    .fill(Color(hex: "0E1236"))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle().stroke(AppColors.Default.goldPrimary, lineWidth: 2)
                    )
                    .overlay(
                        Image("icon_gem")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    )
            }
            .frame(width: 260, height: 260)
            .rotationEffect(.degrees(rotation))

            // المؤشر (السهم)
            VStack {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.5), radius: 5)
                Spacer()
            }
            .frame(height: 280)
        }
    }

    // MARK: شريحة واحدة
    private func wheelSlice(index: Int, total: Int) -> some View {
        let angle = 360.0 / Double(total)
        let startAngle = Double(index) * angle - 90
        let color = sliceColors[index % sliceColors.count]

        return ZStack {
            // الشكل
            Path { path in
                path.move(to: CGPoint(x: 130, y: 130))
                path.addArc(
                    center: CGPoint(x: 130, y: 130),
                    radius: 130,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(startAngle + angle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color.opacity(0.8))

            // النص
            if index < viewModel.slots.count {
                Text(viewModel.slots[index].label)
                    .font(.cairo(.bold, size: 9))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(startAngle + angle / 2 + 90))
                    .offset(
                        x: 80 * cos(CGFloat(startAngle + angle / 2) * .pi / 180),
                        y: 80 * sin(CGFloat(startAngle + angle / 2) * .pi / 180)
                    )
            }
        }
        .frame(width: 260, height: 260)
    }

    // MARK: - زر الدوران
    private var spinButton: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            if viewModel.canSpin {
                GradientButton(
                    title: "دوّر مجاناً!",
                    icon: "icon_gem",
                    colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                    isLoading: viewModel.isSpinning,
                    isEnabled: !viewModel.isSpinning
                ) {
                    spin(useExtra: false)
                }
            } else {
                // عداد تنازلي
                Text("الدوران المجاني بعد \(viewModel.countdownText)")
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: خيارات الدوران الإضافي
    private var extraSpinInfo: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            if !viewModel.canSpin {
                // مشاهدة إعلان = دوران مجاني
                Button {
                    watchAdForSpin()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 16))
                        Text("شاهد إعلان = دوران مجاني")
                            .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppSizes.Button.medium)
                    .background(AppColors.Default.success.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                }
                .disabled(!adManager.isRewardedAdReady)
                .opacity(adManager.isRewardedAdReady ? 1 : 0.5)

                // أو شراء بالجواهر
                if viewModel.extraSpinsUsed < viewModel.maxExtraSpins {
                    Button { spin(useExtra: true) } label: {
                        HStack(spacing: 4) {
                            Image("icon_gem").resizable().frame(width: 14, height: 14)
                            Text("\(viewModel.extraSpinCost)")
                                .font(.poppins(.bold, size: AppSizes.Font.caption))
                                .foregroundStyle(AppColors.Default.goldPrimary)
                            Text("دوران بالجواهر (\(viewModel.extraSpinsUsed)/\(viewModel.maxExtraSpins))")
                                .font(.cairo(.medium, size: AppSizes.Font.caption))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, AppSizes.Spacing.md)
                        .padding(.vertical, AppSizes.Spacing.xs)
                        .background(.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - مشاهدة إعلان مكافأة
    private func watchAdForSpin() {
        adManager.showRewardedAd { rewarded in
            if rewarded {
                HapticManager.success()
                spin(useExtra: false)
            }
        }
    }

    // MARK: - نتيجة الدوران
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
                .onTapGesture { viewModel.dismissResult() }

            VStack(spacing: AppSizes.Spacing.xl) {
                Text("🎉")
                    .font(.system(size: 60))

                Text("مبروك!")
                    .font(.cairo(.black, size: AppSizes.Font.title1))
                    .foregroundStyle(AppColors.Default.goldPrimary)

                if let reward = viewModel.resultReward {
                    Text(reward.label)
                        .font(.cairo(.bold, size: AppSizes.Font.title2))
                        .foregroundStyle(.white)
                }

                GradientButton(
                    title: "ممتاز",
                    colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary]
                ) {
                    viewModel.dismissResult()
                }
                .frame(width: 200)
            }
            .padding(AppSizes.Spacing.xxl)
        }
        .transition(.opacity)
    }

    // MARK: - تنفيذ الدوران
    private func spin(useExtra: Bool) {
        // أنيميشن الدوران
        withAnimation(.easeInOut(duration: 3.5)) {
            rotation += Double.random(in: 1440...2160) // 4-6 لفات
        }

        Task {
            if useExtra {
                await viewModel.spinExtra()
            } else {
                await viewModel.spinFree()
            }
        }
    }
}

#Preview {
    SpinWheelView()
        .environment(\.layoutDirection, .rightToLeft)
}
