//
//  MainView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI
import Lottie

// MARK: - الشاشة الرئيسية (Landscape)
struct MainView: View {

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            GradientBackground.main

            GeometryReader { geo in
                HStack(spacing: 0) {
                    // ═══════ الجانب الأيمن: الملف + القلعة ═══════
                    rightPanel(geo: geo)
                        .frame(width: geo.size.width * 0.38)

                    // ═══════ الجانب الأيسر: التحديات (scroll أفقي) ═══════
                    leftPanel
                        .frame(width: geo.size.width * 0.62)
                }
            }

            // أزرار سريعة عائمة
            floatingButtons

            // طبقة البحث
            if viewModel.isSearching {
                MatchSearchOverlay(modeName: viewModel.searchMode?.title) {
                    viewModel.cancelSearch()
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(.container, edges: .all)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isSearching)
        .forceLandscape()
        .sheet(isPresented: $viewModel.showRoomCode) {
            RoomCodeSheet(code: viewModel.roomCode ?? "")
        }
        .sheet(isPresented: $viewModel.showFriendPicker) {
            FriendPickerSheet(friends: viewModel.friends) { friend in
                viewModel.inviteFriend(friend)
            }
        }
        .sheet(isPresented: $viewModel.showJoinRoom) {
            JoinRoomSheet { code in viewModel.joinRoom(code: code) }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - ═══════ الجانب الأيمن ═══════

    private func rightPanel(geo: GeometryProxy) -> some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // الملف الشخصي
            profileHeader

            Spacer()

            // القلعة
            LottieView(name: "Castle", loopMode: .loop, speed: 0.7)
                .frame(maxWidth: .infinity)
                .frame(height: geo.size.height * 0.5)
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                        .stroke(AppColors.Default.goldPrimary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: AppColors.Default.goldPrimary.opacity(0.2), radius: 15)

            Spacer()
        }
        .padding(AppSizes.Spacing.lg)
    }

    // MARK: الملف الشخصي
    private var profileHeader: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            // الأفاتار
            AvatarView(imageURL: authManager.currentUser?.avatarUrl, size: 52)
                .overlay(Circle().stroke(AppColors.Default.goldPrimary, lineWidth: 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.currentUser?.username ?? "محارب")
                    .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(AppStrings.Main.level) \(authManager.currentUser?.level ?? 1)")
                    .font(.cairo(.medium, size: AppSizes.Font.caption))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            }

            Spacer()

            // الجواهر
            gemsView
        }
    }

    // MARK: الجواهر
    private var gemsView: some View {
        HStack(spacing: 4) {
            Image("icon_gem")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("\(authManager.currentUser?.gems ?? 0)")
                .font(.poppins(.bold, size: AppSizes.Font.caption))
                .foregroundStyle(AppColors.Default.goldPrimary)
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, AppSizes.Spacing.xs)
        .background(.white.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - ═══════ الجانب الأيسر: التحديات ═══════

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.md) {
            // عنوان + كود
            HStack {
                Text("التحديات")
                    .font(.cairo(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    viewModel.showJoinRoom = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 12))
                        Text(AppStrings.Main.joinRoom)
                            .font(.cairo(.medium, size: AppSizes.Font.caption))
                    }
                    .foregroundStyle(AppColors.Default.goldPrimary)
                }
            }
            .padding(.top, AppSizes.Spacing.xl)

            // الـ Scroll الأفقي
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSizes.Spacing.md) {
                    ForEach(GameMode.allCases) { mode in
                        landscapeGameCard(mode)
                    }
                }
                .padding(.trailing, AppSizes.Spacing.lg)
            }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    // MARK: بطاقة وضع لعب (عرضية)
    private func landscapeGameCard(_ mode: GameMode) -> some View {
        Button {
            HapticManager.medium()
            viewModel.selectMode(mode)
        } label: {
            VStack(spacing: AppSizes.Spacing.sm) {
                // الأيقونة في دائرة
                ZStack {
                    Circle()
                        .fill(mode.accentColor.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(mode.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                }

                Text(mode.title)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(width: 120)
            .padding(.vertical, AppSizes.Spacing.lg)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(mode.accentColor.opacity(0.25), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - ═══════ أزرار عائمة ═══════

    private var floatingButtons: some View {
        VStack {
            HStack {
                // الإشعارات (أعلى يسار)
                Button {} label: {
                    ZStack(alignment: .topLeading) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.6))

                        if viewModel.unreadCount > 0 {
                            Text("\(min(viewModel.unreadCount, 9))")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 14, height: 14)
                                .background(AppColors.Default.error)
                                .clipShape(Circle())
                                .offset(x: -4, y: -3)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                }

                Spacer()

                // الإعدادات (أعلى يمين)
                Button {} label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.top, AppSizes.Spacing.md)

            Spacer()

            // أسفل: مكافأة + عجلة
            HStack(spacing: AppSizes.Spacing.md) {
                Spacer()

                miniActionButton(icon: "gift.fill", badge: viewModel.canClaimDaily) {
                    // TODO: شاشة المكافأة اليومية
                }

                miniActionButton(icon: "arrow.trianglehead.2.counterclockwise.rotate.90", badge: viewModel.canSpin) {
                    // TODO: شاشة عجلة الحظ
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.md)
        }
    }

    // MARK: زر صغير عائم
    private func miniActionButton(icon: String, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            ZStack(alignment: .topLeading) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1))

                if badge {
                    Circle()
                        .fill(AppColors.Default.error)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: 2)
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environment(\.layoutDirection, .rightToLeft)
}
