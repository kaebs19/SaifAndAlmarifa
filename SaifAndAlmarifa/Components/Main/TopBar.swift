//
//  TopBar.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - الشريط العلوي
struct TopBar: View {
    let user: User?
    var unreadCount: Int = 0
    var onAvatarTap: () -> Void = {}
    var onNotificationsTap: () -> Void = {}

    var body: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            // الأفاتار + الاسم
            Button(action: onAvatarTap) {
                HStack(spacing: AppSizes.Spacing.sm) {
                    AvatarView(imageURL: user?.avatarUrl, size: AppSizes.Avatar.medium)
                        .overlay(Circle().stroke(AppColors.Default.goldPrimary, lineWidth: 2))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user?.username ?? "محارب")
                            .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                            .foregroundStyle(.white)

                        Text("\(AppStrings.Main.level) \(user?.level ?? 1)")
                            .font(.cairo(.medium, size: AppSizes.Font.caption))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // الجواهر
            HStack(spacing: 4) {
                Image("icon_gem")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text("\(user?.gems ?? 0)")
                    .font(.poppins(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            }
            .padding(.horizontal, AppSizes.Spacing.sm)
            .padding(.vertical, AppSizes.Spacing.xs)
            .background(.white.opacity(0.08))
            .clipShape(Capsule())

            // الإشعارات
            Button(action: onNotificationsTap) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.7))

                    if unreadCount > 0 {
                        Text("\(min(unreadCount, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(AppColors.Default.error)
                            .clipShape(Circle())
                            .offset(x: -6, y: -4)
                    }
                }
                .frame(width: 36, height: 36)
            }
        }
    }
}
