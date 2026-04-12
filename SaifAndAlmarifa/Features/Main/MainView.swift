//
//  MainView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - الشاشة الرئيسية (Landscape — نمط لودو ستار)
struct MainView: View {

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            background

            GeometryReader { geo in
                let isCompact = geo.size.height < 380

                HStack(spacing: 0) {
                    // ═══════ العمود الأيمن: عناصر جانبية ═══════
                    sideColumn(leading: false, isCompact: isCompact)
                        .frame(width: 70)

                    // ═══════ المحتوى الرئيسي ═══════
                    VStack(spacing: isCompact ? 8 : AppSizes.Spacing.md) {
                        topBar(isCompact: isCompact)
                        mainCards(geo: geo, isCompact: isCompact)
                        bottomModes(isCompact: isCompact)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)

                    // ═══════ العمود الأيسر: عناصر جانبية ═══════
                    sideColumn(leading: true, isCompact: isCompact)
                        .frame(width: 70)
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
        .ignoresSafeArea()
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

    // MARK: - ═══════ الخلفية ═══════

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A0E27"), Color(hex: "15103A"), Color(hex: "0D0B2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // نجوم
            Canvas { context, size in
                for _ in 0..<50 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let s = CGFloat.random(in: 1...2)
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

    private func topBar(isCompact: Bool) -> some View {
        HStack(spacing: AppSizes.Spacing.md) {
            // الملف الشخصي
            HStack(spacing: AppSizes.Spacing.sm) {
                AvatarView(imageURL: authManager.currentUser?.avatarUrl, size: isCompact ? 36 : 44)
                    .overlay(Circle().stroke(AppColors.Default.goldPrimary, lineWidth: 2))

                VStack(alignment: .leading, spacing: 1) {
                    Text(authManager.currentUser?.username ?? "محارب")
                        .font(.cairo(.bold, size: isCompact ? 13 : AppSizes.Font.body))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(AppStrings.Main.level) \(authManager.currentUser?.level ?? 1)")
                        .font(.cairo(.medium, size: 10))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
            }

            Spacer()

            // عنوان التطبيق
            Text(AppStrings.Auth.appTitle)
                .font(.cairo(.bold, size: isCompact ? 16 : AppSizes.Font.title3))
                .foregroundStyle(AppColors.Default.goldPrimary)

            Spacer()

            // الجواهر + إشعارات + إعدادات
            HStack(spacing: AppSizes.Spacing.sm) {
                gemsBadge(isCompact: isCompact)

                notificationButton

                Button {} label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, AppSizes.Spacing.md)
    }

    // MARK: الجواهر
    private func gemsBadge(isCompact: Bool) -> some View {
        HStack(spacing: 4) {
            Image("icon_gem")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("\(authManager.currentUser?.gems ?? 0)")
                .font(.poppins(.bold, size: isCompact ? 12 : AppSizes.Font.body))
                .foregroundStyle(AppColors.Default.goldPrimary)
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, 5)
        .background(.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.25), lineWidth: 1))
    }

    // MARK: الإشعارات
    private var notificationButton: some View {
        Button {} label: {
            ZStack(alignment: .topLeading) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.06))
                    .clipShape(Circle())

                if viewModel.unreadCount > 0 {
                    Text("\(min(viewModel.unreadCount, 9))")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(AppColors.Default.error)
                        .clipShape(Circle())
                        .offset(x: -2, y: -2)
                }
            }
        }
    }

    // MARK: - ═══════ البطاقتين الرئيسيتين ═══════

    private func mainCards(geo: GeometryProxy, isCompact: Bool) -> some View {
        let cardH: CGFloat = isCompact ? geo.size.height * 0.38 : geo.size.height * 0.42

        return HStack(spacing: AppSizes.Spacing.lg) {
            // 1v1 عشوائي
            mainCard(
                mode: .random1v1,
                colors: [Color(hex: "FFD700"), Color(hex: "F59E0B")],
                height: cardH
            )

            // 4 لاعبين
            mainCard(
                mode: .random4,
                colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
                height: cardH
            )
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    // MARK: بطاقة رئيسية كبيرة
    private func mainCard(mode: GameMode, colors: [Color], height: CGFloat) -> some View {
        Button {
            HapticManager.medium()
            viewModel.selectMode(mode)
        } label: {
            VStack(spacing: AppSizes.Spacing.sm) {
                // الأيقونة
                Image(mode.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .shadow(color: colors[0].opacity(0.5), radius: 10)

                Text(mode.title)
                    .font(.cairo(.black, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: [colors[0].opacity(0.2), colors[1].opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [colors[0].opacity(0.5), colors[1].opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: colors[0].opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - ═══════ أوضاع أسفل (خاص / صديق / أصحابي) ═══════

    private func bottomModes(isCompact: Bool) -> some View {
        HStack(spacing: AppSizes.Spacing.md) {
            smallModeCard(.private1v1, isCompact: isCompact)
            smallModeCard(.challengeFriend, isCompact: isCompact)
            smallModeCard(.friends4, isCompact: isCompact)

            Spacer()

            // الانضمام بكود
            Button { viewModel.showJoinRoom = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 11))
                    Text("كود")
                        .font(.cairo(.medium, size: 11))
                }
                .foregroundStyle(AppColors.Default.goldPrimary)
                .padding(.horizontal, AppSizes.Spacing.sm)
                .padding(.vertical, 6)
                .background(.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    // MARK: بطاقة وضع صغيرة
    private func smallModeCard(_ mode: GameMode, isCompact: Bool) -> some View {
        Button {
            HapticManager.medium()
            viewModel.selectMode(mode)
        } label: {
            HStack(spacing: AppSizes.Spacing.xs) {
                Image(mode.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 0) {
                    Text(mode.title)
                        .font(.cairo(.bold, size: isCompact ? 11 : 12))
                        .foregroundStyle(.white)
                    Text(mode.subtitle)
                        .font(.cairo(.regular, size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, AppSizes.Spacing.sm)
            .padding(.vertical, 6)
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.small)
                    .stroke(mode.accentColor.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - ═══════ الأعمدة الجانبية ═══════

    private func sideColumn(leading: Bool, isCompact: Bool) -> some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            Spacer()

            if leading {
                // يسار: عجلة + مكافأة
                sideButton(icon: "gift.fill", label: "مكافأة", color: AppColors.Default.warning, badge: viewModel.canClaimDaily) {}
                sideButton(icon: "arrow.trianglehead.2.counterclockwise.rotate.90", label: "حظ", color: AppColors.Default.info, badge: viewModel.canSpin) {}
            } else {
                // يمين (فاضي حالياً — يمكن إضافة عناصر لاحقاً)
                EmptyView()
            }

            Spacer()
        }
        .padding(.vertical, AppSizes.Spacing.md)
    }

    // MARK: زر جانبي
    private func sideButton(icon: String, label: String, color: Color, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                        .frame(width: 44, height: 44)
                        .background(color.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 1))

                    if badge {
                        Circle().fill(AppColors.Default.error).frame(width: 8, height: 8).offset(x: 2, y: 2)
                    }
                }
                Text(label)
                    .font(.cairo(.medium, size: 9))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    MainView()
        .environment(\.layoutDirection, .rightToLeft)
}
