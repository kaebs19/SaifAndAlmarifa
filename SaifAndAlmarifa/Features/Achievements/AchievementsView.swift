//
//  AchievementsView.swift
//  SaifAndAlmarifa
//

import SwiftUI

struct AchievementsView: View {

    @StateObject private var vm = AchievementsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAchievement: Achievement?

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                progressBar
                content
            }
        }
        .task { await vm.load() }
        .sheet(item: $selectedAchievement) { ach in
            AchievementDetailSheet(achievement: ach)
                .presentationDetents([.height(380)])
                .presentationBackground(Color(hex: "1A1410"))
        }
        .navigationBarBackButtonHidden(true)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "0F0A06"), Color(hex: "1F1410")],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("الإنجازات")
                    .font(.cairo(.black, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)
                Text("\(vm.unlockedCount) من \(vm.totalCount)")
                    .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "trophy.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppColors.Default.goldPrimary)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.top, AppSizes.Spacing.md)
        .padding(.bottom, AppSizes.Spacing.sm)
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 8)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FF6B35")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * vm.progress, height: 8)
                        .animation(.spring(response: 0.5), value: vm.progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.bottom, AppSizes.Spacing.md)
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.achievements.isEmpty {
            Spacer()
            ProgressView().tint(AppColors.Default.goldPrimary)
            Spacer()
        } else if vm.achievements.isEmpty {
            Spacer()
            Text("لا توجد إنجازات بعد")
                .font(.cairo(.semiBold, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(vm.achievements) { ach in
                        AchievementCard(achievement: ach)
                            .onTapGesture { selectedAchievement = ach }
                    }
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.bottom, AppSizes.Spacing.xl)
            }
        }
    }
}

// MARK: - Card

struct AchievementCard: View {
    let achievement: Achievement

    private var color: Color { Color(hex: achievement.color) }
    private var unlocked: Bool { achievement.isUnlocked == true }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? color.opacity(0.18) : Color.white.opacity(0.04))
                    .frame(width: 64, height: 64)
                Image(systemName: achievement.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(unlocked ? color : Color.white.opacity(0.25))
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(4)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                        .offset(x: 22, y: 22)
                }
            }

            Text(achievement.titleAr)
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(unlocked ? .white : Color.white.opacity(0.55))
                .lineLimit(1)

            Text(achievement.descAr)
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32, alignment: .top)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(unlocked ? 0.06 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(unlocked ? color.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement

    private var color: Color { Color(hex: achievement.color) }
    private var unlocked: Bool { achievement.isUnlocked == true }

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.white.opacity(0.18))
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            ZStack {
                Circle()
                    .fill(color.opacity(unlocked ? 0.25 : 0.08))
                    .frame(width: 110, height: 110)
                Image(systemName: achievement.icon)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(unlocked ? color : Color.white.opacity(0.3))
            }
            .padding(.top, 8)

            Text(achievement.titleAr)
                .font(.cairo(.black, size: AppSizes.Font.title2))
                .foregroundStyle(.white)

            Text(achievement.descAr)
                .font(.cairo(.semiBold, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSizes.Spacing.lg)

            HStack(spacing: 16) {
                rewardChip(icon: "circle.fill", label: "+\(achievement.rewardGold)", color: AppColors.Default.goldPrimary, suffix: "ذهب")
                rewardChip(icon: "star.fill", label: "+\(achievement.rewardXp)", color: Color(hex: "60A5FA"), suffix: "XP")
            }
            .padding(.top, 4)

            if unlocked {
                Label("مفتوح ✨", systemImage: "checkmark.seal.fill")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(color)
                    .padding(.top, 2)
            } else {
                Text("لم يُفتح بعد")
                    .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.bottom, AppSizes.Spacing.lg)
    }

    private func rewardChip(icon: String, label: String, color: Color, suffix: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(label).foregroundStyle(.white)
            Text(suffix).foregroundStyle(.white.opacity(0.6))
        }
        .font(.cairo(.bold, size: AppSizes.Font.body))
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}
