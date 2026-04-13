//
//  DailyRewardView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import SwiftUI

// MARK: - شاشة المكافأة اليومية
struct DailyRewardView: View {

    @StateObject private var viewModel = DailyRewardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSizes.Spacing.sm), count: 4)

    var body: some View {
        ZStack {
            GradientBackground.main

            VStack(spacing: AppSizes.Spacing.lg) {
                header
                streakInfo
                rewardsGrid
                claimButton
                Spacer()
            }
            .padding(AppSizes.Spacing.lg)

            // أنيميشن المطالبة
            if viewModel.showClaimed {
                claimedOverlay
            }
        }
        .task {
            await viewModel.onAppear()
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { appeared = true }
        }
    }

    // MARK: الهيدر
    private var header: some View {
        ZStack {
            Text(AppStrings.Main.dailyReward)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
    }

    // MARK: معلومات الـ Streak
    private var streakInfo: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            // أيقونة
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

            Text("اليوم \(viewModel.status?.currentDay ?? 1) من 7")
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(.white)

            HStack(spacing: 4) {
                Image(systemName: "flame")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                Text("سلسلة: \(viewModel.status?.streak ?? 0) يوم")
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: شبكة المكافآت (7 أيام)
    private var rewardsGrid: some View {
        let rewards = viewModel.status?.rewards ?? []

        return VStack(spacing: AppSizes.Spacing.sm) {
            // الصف الأول: أول 4 أيام
            LazyVGrid(columns: columns, spacing: AppSizes.Spacing.sm) {
                ForEach(Array(rewards.prefix(4).enumerated()), id: \.offset) { i, reward in
                    dayCard(day: i + 1, reward: reward)
                }
            }

            // الصف الثاني: الأيام 5-7
            if rewards.count > 4 {
                let threeColumns = Array(repeating: GridItem(.flexible(), spacing: AppSizes.Spacing.sm), count: 3)
                LazyVGrid(columns: threeColumns, spacing: AppSizes.Spacing.sm) {
                    ForEach(Array(rewards.dropFirst(4).enumerated()), id: \.offset) { i, reward in
                        dayCard(day: i + 5, reward: reward)
                    }
                }
            }
        }
    }

    // MARK: بطاقة يوم واحد
    private func dayCard(day: Int, reward: DailyRewardItem?) -> some View {
        let currentDay = viewModel.status?.currentDay ?? 1
        let isClaimed = day < currentDay
        let isToday = day == currentDay
        let isLocked = day > currentDay

        return VStack(spacing: AppSizes.Spacing.xs) {
            Text("يوم \(day)")
                .font(.cairo(.bold, size: 11))
                .foregroundStyle(isToday ? AppColors.Default.goldPrimary : .white.opacity(0.6))

            // الأيقونة
            ZStack {
                if isClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.Default.success)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.3))
                } else {
                    rewardIcon(reward)
                }
            }
            .frame(height: 36)

            Text(reward?.label ?? "")
                .font(.cairo(.medium, size: 9))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(
            isToday
                ? AppColors.Default.goldPrimary.opacity(0.12)
                : .white.opacity(isClaimed ? 0.02 : 0.04)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(
                    isToday ? AppColors.Default.goldPrimary.opacity(0.5) : .white.opacity(0.06),
                    lineWidth: isToday ? 2 : 1
                )
        )
        .opacity(isLocked ? 0.5 : 1)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7).delay(Double(day) * 0.08),
            value: appeared
        )
    }

    // MARK: أيقونة المكافأة
    @ViewBuilder
    private func rewardIcon(_ reward: DailyRewardItem?) -> some View {
        switch reward?.type {
        case "gems":
            Image("icon_gem")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        case "item":
            Image("icon_shield")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        default:
            Image(systemName: "gift.fill")
                .font(.system(size: 24))
                .foregroundStyle(AppColors.Default.goldPrimary)
        }
    }

    // MARK: زر المطالبة
    private var claimButton: some View {
        GradientButton(
            title: viewModel.status?.claimed == true ? "تم الاستلام ✓" : "استلم مكافأتك!",
            icon: viewModel.status?.claimed == true ? nil : "icon_gem",
            colors: viewModel.status?.claimed == true
                ? [.gray.opacity(0.3), .gray.opacity(0.2)]
                : [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
            isLoading: viewModel.isLoading,
            isEnabled: viewModel.status?.claimed == false
        ) {
            Task { await viewModel.claim() }
        }
    }

    // MARK: أنيميشن المطالبة
    private var claimedOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { viewModel.showClaimed = false }

            VStack(spacing: AppSizes.Spacing.xl) {
                Text("🎉").font(.system(size: 60))

                Text("مبروك!")
                    .font(.cairo(.black, size: AppSizes.Font.title1))
                    .foregroundStyle(AppColors.Default.goldPrimary)

                if let reward = viewModel.claimedReward {
                    VStack(spacing: AppSizes.Spacing.sm) {
                        rewardIcon(reward)
                            .scaleEffect(1.5)
                        Text(reward.label)
                            .font(.cairo(.bold, size: AppSizes.Font.title2))
                            .foregroundStyle(.white)
                    }
                }

                GradientButton(
                    title: "ممتاز!",
                    colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary]
                ) {
                    viewModel.showClaimed = false
                }
                .frame(width: 200)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    DailyRewardView()
        .environment(\.layoutDirection, .rightToLeft)
}
