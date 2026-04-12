//
//  MainView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - الشاشة الرئيسية (Portrait)
struct MainView: View {

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSizes.Spacing.lg) {
                    topBar
                    mainCards
                    secondaryModes
                    quickActions
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.top, AppSizes.Spacing.md)
                .padding(.bottom, AppSizes.Spacing.xxl)
            }

            // طبقة البحث
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
            JoinRoomSheet { code in viewModel.joinRoom(code: code) }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - ═══════ الخلفية ═══════

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A0E27"), Color(hex: "15103A"), Color(hex: "0D0B2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Canvas { context, size in
                for _ in 0..<60 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let s = CGFloat.random(in: 1...2.5)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)),
                        with: .color(.white.opacity(Double.random(in: 0.08...0.3)))
                    )
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - ═══════ الشريط العلوي ═══════

    private var topBar: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            // الملف الشخصي
            AvatarView(imageURL: authManager.currentUser?.avatarUrl, size: 48)
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
            HStack(spacing: 5) {
                Image("icon_gem").resizable().scaledToFit().frame(width: 18, height: 18)
                Text("\(authManager.currentUser?.gems ?? 0)")
                    .font(.poppins(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            }
            .padding(.horizontal, AppSizes.Spacing.sm)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.25), lineWidth: 1))

            // الإشعارات
            ZStack(alignment: .topLeading) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.06))
                    .clipShape(Circle())

                if viewModel.unreadCount > 0 {
                    Text("\(min(viewModel.unreadCount, 9))")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 15, height: 15)
                        .background(AppColors.Default.error)
                        .clipShape(Circle())
                        .offset(x: -3, y: -3)
                }
            }

            // إعدادات
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.06))
                .clipShape(Circle())
        }
    }

    // MARK: - ═══════ البطاقتين الرئيسيتين ═══════

    private var mainCards: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            mainCard(
                mode: .random1v1,
                gradient: [Color(hex: "B8860B"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                shadowColor: Color(hex: "FFD700")
            )

            mainCard(
                mode: .random4,
                gradient: [Color(hex: "7F1D1D"), Color(hex: "DC2626"), Color(hex: "991B1B")],
                shadowColor: Color(hex: "EF4444")
            )
        }
    }

    private func mainCard(mode: GameMode, gradient: [Color], shadowColor: Color) -> some View {
        Button {
            HapticManager.medium()
            viewModel.selectMode(mode)
        } label: {
            VStack(spacing: AppSizes.Spacing.md) {
                // الأيقونة مع توهج
                Image(mode.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .shadow(color: shadowColor.opacity(0.6), radius: 12)

                Text(mode.title)
                    .font(.cairo(.black, size: AppSizes.Font.title1))
                    .foregroundStyle(.white)

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                LinearGradient(colors: gradient.map { $0.opacity(0.3) },
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                    .stroke(
                        LinearGradient(colors: [gradient[1].opacity(0.6), gradient[0].opacity(0.2)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
            )
            .shadow(color: shadowColor.opacity(0.2), radius: 15, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - ═══════ الأوضاع الثانوية ═══════

    private var secondaryModes: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            secondaryCard(.private1v1)
            secondaryCard(.challengeFriend)
            secondaryCard(.friends4)
        }
    }

    private func secondaryCard(_ mode: GameMode) -> some View {
        Button {
            HapticManager.medium()
            viewModel.selectMode(mode)
        } label: {
            VStack(spacing: AppSizes.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(mode.accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(mode.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                }

                Text(mode.title)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.md)
            .background(.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(mode.accentColor.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - ═══════ الإجراءات السريعة ═══════

    private var quickActions: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            // مكافأة يومية
            actionCard(icon: "gift.fill", title: AppStrings.Main.dailyReward,
                       color: AppColors.Default.warning, badge: viewModel.canClaimDaily) {}

            // عجلة الحظ
            actionCard(icon: "arrow.trianglehead.2.counterclockwise.rotate.90",
                       title: AppStrings.Main.spinWheel,
                       color: AppColors.Default.info, badge: viewModel.canSpin) {}

            // الانضمام بكود
            actionCard(icon: "keyboard", title: AppStrings.Main.joinRoom,
                       color: AppColors.Default.goldPrimary, badge: false) {
                viewModel.showJoinRoom = true
            }
        }
    }

    private func actionCard(icon: String, title: String, color: Color, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: AppSizes.Spacing.sm) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)

                    if badge {
                        Circle().fill(AppColors.Default.error)
                            .frame(width: 8, height: 8).offset(x: -4, y: -4)
                    }
                }

                Text(title)
                    .font(.cairo(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.md)
            .background(color.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    MainView()
        .environment(\.layoutDirection, .rightToLeft)
}
