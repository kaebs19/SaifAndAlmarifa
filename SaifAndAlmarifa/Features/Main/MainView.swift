//
//  MainView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - الشاشة الرئيسية (Landscape)
struct MainView: View {

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            // الخلفية
            LinearGradient(
                colors: [Color(hex: "0A0E27"), Color(hex: "1A1147"), Color(hex: "0D0B2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // نجوم خافتة
            starsBackground

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // ═══════ الشريط العلوي ═══════
                    topSection(geo: geo)
                        .padding(.horizontal, AppSizes.Spacing.lg)
                        .padding(.top, AppSizes.Spacing.sm)

                    Spacer(minLength: AppSizes.Spacing.md)

                    // ═══════ البطاقات ═══════
                    challengesSection
                        .padding(.horizontal, AppSizes.Spacing.lg)

                    Spacer(minLength: AppSizes.Spacing.sm)

                    // ═══════ الشريط السفلي ═══════
                    bottomBar
                        .padding(.horizontal, AppSizes.Spacing.lg)
                        .padding(.bottom, AppSizes.Spacing.sm)
                }
            }

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

    // MARK: - ═══════ الشريط العلوي ═══════

    private func topSection(geo: GeometryProxy) -> some View {
        HStack {
            // إعدادات
            iconButton("gearshape.fill") {}

            Spacer()

            // الجواهر
            HStack(spacing: 6) {
                Image("icon_gem")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("\(authManager.currentUser?.gems ?? 0)")
                    .font(.poppins(.bold, size: AppSizes.Font.bodyLarge))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            }
            .padding(.horizontal, AppSizes.Spacing.md)
            .padding(.vertical, AppSizes.Spacing.xs)
            .background(.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.2), lineWidth: 1))

            Spacer()

            // الإشعارات
            ZStack(alignment: .topLeading) {
                iconButton("bell.fill") {}
                if viewModel.unreadCount > 0 {
                    Text("\(min(viewModel.unreadCount, 9))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(AppColors.Default.error)
                        .clipShape(Circle())
                        .offset(x: -2, y: -2)
                }
            }

            Spacer()

            // الملف الشخصي
            HStack(spacing: AppSizes.Spacing.sm) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(authManager.currentUser?.username ?? "محارب")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                    Text("\(AppStrings.Main.level) \(authManager.currentUser?.level ?? 1)")
                        .font(.cairo(.medium, size: 11))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }

                AvatarView(imageURL: authManager.currentUser?.avatarUrl, size: 44)
                    .overlay(Circle().stroke(AppColors.Default.goldPrimary, lineWidth: 2))
            }
        }
    }

    // MARK: - ═══════ التحديات ═══════

    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.sm) {
            // العنوان
            Text("التحديات")
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(.white)

            // Scroll أفقي
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSizes.Spacing.md) {
                    ForEach(GameMode.allCases) { mode in
                        gameModeCard(mode)
                    }
                }
                .padding(.vertical, AppSizes.Spacing.xs)
            }
        }
    }

    // MARK: بطاقة وضع لعب
    private func gameModeCard(_ mode: GameMode) -> some View {
        Button {
            HapticManager.medium()
            viewModel.selectMode(mode)
        } label: {
            VStack(spacing: AppSizes.Spacing.sm) {
                // الأيقونة
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [mode.accentColor.opacity(0.3), mode.accentColor.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(mode.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }

                Text(mode.title)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(width: 110, height: 140)
            .background(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .fill(.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                            .stroke(
                                LinearGradient(
                                    colors: [mode.accentColor.opacity(0.4), mode.accentColor.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - ═══════ الشريط السفلي ═══════

    private var bottomBar: some View {
        HStack {
            // المكافأة اليومية
            miniButton(icon: "gift.fill", label: "مكافأة", badge: viewModel.canClaimDaily) {}

            miniButton(icon: "arrow.trianglehead.2.counterclockwise.rotate.90", label: "حظ", badge: viewModel.canSpin) {}

            Spacer()

            // الانضمام بكود
            Button {
                viewModel.showJoinRoom = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 13))
                    Text(AppStrings.Main.joinRoom)
                        .font(.cairo(.medium, size: AppSizes.Font.caption))
                }
                .foregroundStyle(AppColors.Default.goldPrimary)
                .padding(.horizontal, AppSizes.Spacing.md)
                .padding(.vertical, AppSizes.Spacing.xs)
                .background(.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1))
            }
        }
    }

    // MARK: - ═══════ Helpers ═══════

    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.06))
                .clipShape(Circle())
        }
    }

    private func miniButton(icon: String, label: String, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: 6) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                    if badge {
                        Circle().fill(AppColors.Default.error).frame(width: 7, height: 7).offset(x: -2, y: -2)
                    }
                }
                Text(label)
                    .font(.cairo(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, AppSizes.Spacing.sm)
            .padding(.vertical, AppSizes.Spacing.xs)
            .background(.white.opacity(0.06))
            .clipShape(Capsule())
        }
    }

    // MARK: نجوم خلفية
    private var starsBackground: some View {
        Canvas { context, size in
            for i in 0..<40 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let s = CGFloat.random(in: 1...2.5)
                let opacity = Double.random(in: 0.1...0.35)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    MainView()
        .environment(\.layoutDirection, .rightToLeft)
}
