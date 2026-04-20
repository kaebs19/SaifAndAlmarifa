//
//  InviteFriendsSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Main/MatchLobby/InviteFriendsSheet.swift
//  شيت دعوة الأصدقاء للغرفة — قائمة + زر "دعوة" لكل صديق

import SwiftUI

struct InviteFriendsSheet: View {

    @ObservedObject var viewModel: MainViewModel
    let mode: GameMode

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTab: Int = 0   // 0 = أصدقائي، 1 = بحث عن لاعب

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                tabBar

                searchBar
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .onChange(of: searchText) { _, new in
                        if selectedTab == 1 {
                            Task { await viewModel.searchUsers(new) }
                        }
                    }

                if selectedTab == 0 {
                    if viewModel.friends.isEmpty {
                        emptyState
                    } else {
                        friendsList
                    }
                } else {
                    usersSearchList
                }

                bottomShareBar
            }
            .background(GradientBackground.main)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("تم") { dismiss() }
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
            }
        }
        .task { await viewModel.loadFriends() }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            Text("دعوة أصدقاء")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)

            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11))
                Text("\(viewModel.invitedFriends.count) مدعوين من \(mode.playersRequired - 1)")
            }
            .font(.cairo(.medium, size: 11))
            .foregroundStyle(mode.accentColor)
        }
        .padding(.top, AppSizes.Spacing.md)
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton("أصدقائي", tag: 0)
            tabButton("بحث عن لاعب", tag: 1)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.top, AppSizes.Spacing.sm)
    }

    private func tabButton(_ title: String, tag: Int) -> some View {
        Button {
            HapticManager.selection()
            withAnimation { selectedTab = tag }
            searchText = ""
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                    .foregroundStyle(selectedTab == tag ? AppColors.Default.goldPrimary : .white.opacity(0.4))
                Capsule()
                    .fill(selectedTab == tag ? AppColors.Default.goldPrimary : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Users Search List
    private var usersSearchList: some View {
        ScrollView {
            if searchText.trimmingCharacters(in: .whitespaces).count < 2 {
                VStack(spacing: AppSizes.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("اكتب اسم لاعب للبحث")
                        .font(.cairo(.medium, size: AppSizes.Font.body))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 60)
                .frame(maxWidth: .infinity)
            } else if viewModel.isSearchingUsers {
                ProgressView().tint(.white).padding(.top, 40)
            } else if viewModel.userSearchResults.isEmpty {
                Text("لم نجد نتائج")
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.userSearchResults) { user in
                        userSearchRow(user)
                    }
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.bottom, AppSizes.Spacing.md)
            }
        }
    }

    private func userSearchRow(_ user: FriendSearchResult) -> some View {
        let isInvited = viewModel.invitedFriends.contains(where: { $0.id == user.id })
        let maxReached = !isInvited && viewModel.invitedFriends.count >= (mode.playersRequired - 1)

        return HStack(spacing: AppSizes.Spacing.sm) {
            AvatarView(imageURL: user.avatarUrl, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let lvl = user.level {
                        Text("Lv.\(lvl)")
                            .font(.poppins(.semiBold, size: 10))
                            .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.7))
                    }
                    if let country = user.country, !country.isEmpty {
                        Text("•").foregroundStyle(.white.opacity(0.2))
                        Text(country)
                            .font(.cairo(.regular, size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            Spacer()
            Button {
                HapticManager.selection()
                if isInvited {
                    if let f = viewModel.invitedFriends.first(where: { $0.id == user.id }) {
                        viewModel.uninviteFriend(f)
                    }
                } else if !maxReached {
                    viewModel.inviteUser(user)
                }
            } label: {
                if isInvited {
                    Label("تم", systemImage: "checkmark.circle.fill")
                        .font(.cairo(.bold, size: 11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 6)
                        .background(AppColors.Default.success)
                        .clipShape(Capsule())
                } else {
                    Label("دعوة", systemImage: "plus")
                        .font(.cairo(.bold, size: 11))
                        .foregroundStyle(maxReached ? .white.opacity(0.3) : .black)
                        .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 6)
                        .background(maxReached ? Color.gray.opacity(0.2) : mode.accentColor)
                        .clipShape(Capsule())
                }
            }
            .disabled(maxReached)
        }
        .padding(AppSizes.Spacing.sm)
        .background(isInvited ? mode.accentColor.opacity(0.08) : Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
    }

    // MARK: - Search
    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.4))
            TextField("ابحث في الأصدقاء...", text: $searchText)
                .font(.cairo(.regular, size: AppSizes.Font.body))
                .foregroundStyle(.white)
                .tint(mode.accentColor)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, 10)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - قائمة الأصدقاء
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(filteredFriends) { friend in
                    friendRow(friend)
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.md)
        }
    }

    private var filteredFriends: [Friend] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return viewModel.friends }
        return viewModel.friends.filter { $0.username.localizedCaseInsensitiveContains(q) }
    }

    private func friendRow(_ friend: Friend) -> some View {
        let isInvited = viewModel.invitedFriends.contains(where: { $0.id == friend.id })
        let maxReached = !isInvited && viewModel.invitedFriends.count >= (mode.playersRequired - 1)

        return HStack(spacing: AppSizes.Spacing.sm) {
            AvatarView(
                imageURL: friend.avatarUrl,
                size: 44,
                showOnlineIndicator: true,
                isOnline: friend.isOnline ?? false
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if friend.isOnline == true {
                        Text("متصل")
                            .font(.cairo(.medium, size: 10))
                            .foregroundStyle(AppColors.Default.success)
                    } else {
                        Text("غير متصل")
                            .font(.cairo(.regular, size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    if let lvl = friend.level {
                        Text("•").foregroundStyle(.white.opacity(0.2))
                        Text("Lv.\(lvl)")
                            .font(.poppins(.semiBold, size: 10))
                            .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.7))
                    }
                }
            }
            Spacer()
            inviteButton(for: friend, isInvited: isInvited, disabled: maxReached)
        }
        .padding(AppSizes.Spacing.sm)
        .background(isInvited ? mode.accentColor.opacity(0.08) : .white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(isInvited ? mode.accentColor.opacity(0.35) : .white.opacity(0.08), lineWidth: 1)
        )
        .opacity(maxReached ? 0.5 : 1)
    }

    private func inviteButton(for friend: Friend, isInvited: Bool, disabled: Bool) -> some View {
        Button {
            HapticManager.selection()
            if isInvited {
                viewModel.uninviteFriend(friend)
            } else if !disabled {
                viewModel.inviteFriend(friend)
            }
        } label: {
            if isInvited {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("تم")
                }
                .font(.cairo(.bold, size: 11))
                .foregroundStyle(.white)
                .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 6)
                .background(AppColors.Default.success)
                .clipShape(Capsule())
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("دعوة")
                }
                .font(.cairo(.bold, size: 11))
                .foregroundStyle(disabled ? .white.opacity(0.3) : .black)
                .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 6)
                .background(disabled ? Color.gray.opacity(0.2) : mode.accentColor)
                .clipShape(Capsule())
            }
        }
        .disabled(disabled)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Spacer(minLength: 40)
            Image(systemName: "person.2.slash")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.2))
            Text("لا يوجد أصدقاء بعد")
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.5))
            Text("استخدم مشاركة الكود أدناه بدلاً من ذلك")
                .font(.cairo(.regular, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Share Bar
    private var bottomShareBar: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            Text("أو شارك الكود مباشرة")
                .font(.cairo(.regular, size: 10))
                .foregroundStyle(.white.opacity(0.4))

            HStack(spacing: AppSizes.Spacing.sm) {
                shareChip(icon: "doc.on.doc.fill", label: "نسخ", color: AppColors.Default.goldPrimary) {
                    UIPasteboard.general.string = viewModel.roomCode
                    HapticManager.success()
                    ToastManager.shared.info("تم النسخ")
                }

                if ClanStateManager.shared.myClan != nil {
                    shareChip(icon: "shield.lefthalf.filled", label: "عشيرتي", color: Color(hex: "FFD700")) {
                        Task { await viewModel.shareRoomCodeToClan() }
                    }
                }
            }
        }
        .padding(AppSizes.Spacing.md)
        .background(
            LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func shareChip(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.cairo(.semiBold, size: 11))
            .foregroundStyle(color)
            .padding(.horizontal, AppSizes.Spacing.md).padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}
