//
//  MainView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI
import Lottie

// MARK: - الشاشة الرئيسية
struct MainView: View {

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            GradientBackground.main

            VStack(spacing: 0) {
                // محتوى التاب الحالي
                Group {
                    switch viewModel.selectedTab {
                    case .home:        homeTab
                    case .leaderboard: placeholderTab("المتصدرين", icon: "trophy.fill")
                    case .shop:        placeholderTab("المتجر", icon: "bag.fill")
                    case .profile:     HomeView()
                    }
                }
                .frame(maxHeight: .infinity)

                MainTabBar(selectedTab: $viewModel.selectedTab)
            }

            // طبقة البحث عن مباراة
            if viewModel.isSearching {
                MatchSearchOverlay(modeName: viewModel.searchMode?.title) {
                    viewModel.cancelSearch()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isSearching)
        .sheet(isPresented: $viewModel.showRoomCode) {
            RoomCodeSheet(code: viewModel.roomCode ?? "")
        }
        .sheet(isPresented: $viewModel.showFriendPicker) {
            FriendPickerSheet(friends: viewModel.friends) { friend in
                viewModel.inviteFriend(friend)
            }
        }
        .sheet(isPresented: $viewModel.showJoinRoom) {
            JoinRoomSheet { code in
                viewModel.joinRoom(code: code)
            }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - ═══════════════ تاب الرئيسية ═══════════════

    private var homeTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSizes.Spacing.lg) {
                // الشريط العلوي
                TopBar(
                    user: authManager.currentUser,
                    unreadCount: viewModel.unreadCount
                )
                .staggeredAppear(order: 0)

                // القلعة
                LottieView(name: "Castle", loopMode: .loop, speed: 0.7)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
                    .scaleAppear(delay: 0.2)

                // عنوان التحديات
                HStack {
                    Text("التحديات")
                        .font(.cairo(.bold, size: AppSizes.Font.title2))
                        .foregroundStyle(.white)
                    Spacer()

                    // زر الانضمام بكود
                    Button {
                        viewModel.showJoinRoom = true
                    } label: {
                        Label(AppStrings.Main.joinRoom, systemImage: "keyboard")
                            .font(.cairo(.medium, size: AppSizes.Font.caption))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                    }
                }
                .staggeredAppear(order: 1)

                // شبكة أوضاع اللعب (2 عمود)
                gameModeGrid
                    .staggeredAppear(order: 2)

                // إجراءات سريعة
                quickActions
                    .staggeredAppear(order: 3)
            }
            .padding(AppSizes.Spacing.lg)
        }
    }

    // MARK: شبكة أوضاع اللعب
    private var gameModeGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: AppSizes.Spacing.md),
            GridItem(.flexible(), spacing: AppSizes.Spacing.md)
        ]

        return VStack(spacing: AppSizes.Spacing.md) {
            // 4 بطاقات في شبكة 2×2
            LazyVGrid(columns: columns, spacing: AppSizes.Spacing.md) {
                ForEach(Array(GameMode.allCases.prefix(4))) { mode in
                    GameModeCard(mode: mode) {
                        viewModel.selectMode(mode)
                    }
                }
            }

            // البطاقة الخامسة بعرض كامل
            if let lastMode = GameMode.allCases.last {
                GameModeCard(mode: lastMode) {
                    viewModel.selectMode(lastMode)
                }
            }
        }
    }

    // MARK: إجراءات سريعة
    private var quickActions: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            QuickActionButton(
                title: AppStrings.Main.dailyReward,
                icon: "gift.fill",
                badge: viewModel.canClaimDaily
            ) {
                // TODO: شاشة المكافأة اليومية
            }

            QuickActionButton(
                title: AppStrings.Main.spinWheel,
                icon: "arrow.trianglehead.2.counterclockwise.rotate.90",
                badge: viewModel.canSpin
            ) {
                // TODO: شاشة عجلة الحظ
            }
        }
    }

    // MARK: شاشة مؤقتة للتابات الأخرى
    private func placeholderTab(_ title: String, icon: String) -> some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.2))
            Text(title)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white.opacity(0.3))
            Text("قريباً")
                .font(.cairo(.regular, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.2))
            Spacer()
        }
    }
}

#Preview {
    MainView()
        .environment(\.layoutDirection, .rightToLeft)
}
