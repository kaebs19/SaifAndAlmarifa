//
//  FriendPickerSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - اختيار صديق للدعوة
struct FriendPickerSheet: View {
    let friends: [Friend]
    let onInvite: (Friend) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if friends.isEmpty {
                    emptyState
                } else {
                    friendList
                }
            }
            .background(Color(hex: "0E1236"))
            .navigationTitle(AppStrings.Main.selectFriend)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0E1236"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: قائمة الأصدقاء
    private var friendList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(friends) { friend in
                    HStack(spacing: AppSizes.Spacing.md) {
                        AvatarView(
                            imageURL: friend.avatarUrl,
                            size: AppSizes.Avatar.medium,
                            showOnlineIndicator: true,
                            isOnline: friend.isOnline ?? false
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.username)
                                .font(.cairo(.semiBold, size: AppSizes.Font.bodyLarge))
                                .foregroundStyle(.white)
                            Text("\(AppStrings.Main.level) \(friend.level ?? 1)")
                                .font(.cairo(.regular, size: AppSizes.Font.caption))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Button {
                            onInvite(friend)
                            dismiss()
                        } label: {
                            Text(AppStrings.Main.invite)
                                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                                .foregroundStyle(AppColors.Default.goldPrimary)
                                .padding(.horizontal, AppSizes.Spacing.md)
                                .padding(.vertical, AppSizes.Spacing.xs)
                                .overlay(
                                    Capsule().stroke(AppColors.Default.goldPrimary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.vertical, AppSizes.Spacing.sm)

                    if friend.id != friends.last?.id {
                        Divider().overlay(.white.opacity(0.06)).padding(.leading, 70)
                    }
                }
            }
        }
    }

    // MARK: حالة فارغة
    private var emptyState: some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.2))
            Text(AppStrings.Main.noFriends)
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
