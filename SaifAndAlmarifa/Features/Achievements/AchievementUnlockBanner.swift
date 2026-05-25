//
//  AchievementUnlockBanner.swift
//  SaifAndAlmarifa
//
//  Banner احتفالي يطفو من الأعلى عند فتح إنجاز
//

import SwiftUI

struct AchievementUnlockBanner: View {
    let unlock: AchievementUnlock
    let onTap: () -> Void

    @State private var isVisible = false

    private var color: Color { Color(hex: unlock.color) }

    var body: some View {
        VStack {
            content
                .padding(.top, 56)
            Spacer()
        }
        .ignoresSafeArea()
        .transition(.move(edge: .top).combined(with: .opacity))
        .onTapGesture(perform: onTap)
    }

    private var content: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.25))
                    .frame(width: 56, height: 56)
                Image(systemName: unlock.icon)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                    Text("إنجاز جديد!")
                        .font(.cairo(.bold, size: AppSizes.Font.caption))
                }
                .foregroundStyle(color)

                Text(unlock.titleAr)
                    .font(.cairo(.black, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if unlock.rewardGold > 0 {
                        rewardChip(symbol: "circle.fill", text: "+\(unlock.rewardGold)", tint: AppColors.Default.goldPrimary)
                    }
                    if unlock.rewardXp > 0 {
                        rewardChip(symbol: "star.fill", text: "+\(unlock.rewardXp) XP", tint: Color(hex: "60A5FA"))
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "1A1410"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: color.opacity(0.5), radius: 16, y: 4)
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    private func rewardChip(symbol: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 9, weight: .bold))
            Text(text).font(.cairo(.bold, size: AppSizes.Font.caption))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(0.12)))
    }
}

// MARK: - View Modifier

struct AchievementUnlockOverlay: ViewModifier {
    @StateObject private var manager = AchievementUnlockManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let unlock = manager.currentlyShowing {
                    AchievementUnlockBanner(unlock: unlock) {
                        manager.dismissCurrent()
                    }
                    .zIndex(999)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.78),
                       value: manager.currentlyShowing?.key)
    }
}

extension View {
    /// إضافة طبقة banner للإنجازات على مستوى التطبيق
    func withAchievementUnlocks() -> some View {
        modifier(AchievementUnlockOverlay())
    }
}
