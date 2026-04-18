//
//  MainView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - الشاشة الرئيسية
struct MainView: View {

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var clanState = ClanStateManager.shared
    @State private var showProfile = false
    @State private var showSpinWheel = false
    @State private var showPlayerCard = false
    @State private var showDailyReward = false
    @State private var showFriends = false
    @State private var showNotifications = false
    @State private var showStore = false
    @State private var showLeaderboard = false
    @State private var showClans = false
    @State private var directClanId: String?
    @State private var appeared = false

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSizes.Spacing.lg) {
                    topBar
                        .staggeredAppear(order: 0)

                    mainCards
                        .staggeredAppear(order: 1)

                    secondaryModes
                        .staggeredAppear(order: 2)

                    quickActions
                        .staggeredAppear(order: 3)
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.top, AppSizes.Spacing.sm)
                .padding(.bottom, AppSizes.Spacing.xxl)
            }
            .refreshable {
                await viewModel.onAppear()
                HapticManager.light()
            }

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
            FriendPickerSheet(friends: viewModel.friends) { viewModel.inviteFriend($0) }
        }
        .sheet(isPresented: $viewModel.showJoinRoom) {
            JoinRoomSheet { viewModel.joinRoom(code: $0) }
        }
        .fullScreenCover(isPresented: $showProfile) { ProfileView() }
        .fullScreenCover(isPresented: $showSpinWheel) { SpinWheelView() }
        .fullScreenCover(isPresented: $showDailyReward) { DailyRewardView() }
        .fullScreenCover(isPresented: $showFriends) { FriendsView() }
        .fullScreenCover(isPresented: $showNotifications) { NotificationsView() }
        .fullScreenCover(isPresented: $showStore) { StoreView() }
        .fullScreenCover(isPresented: $showLeaderboard) { LeaderboardView() }
        .fullScreenCover(isPresented: $showClans) { ClansHubView() }
        .fullScreenCover(item: Binding(
            get: { directClanId.map { IdentifiableString(value: $0) } },
            set: { directClanId = $0?.value }
        )) { wrapper in
            ClanDetailView(clanId: wrapper.value) { directClanId = nil }
        }
        .playerCard(
            isPresented: $showPlayerCard,
            data: authManager.currentUser.map {
                PlayerCardData.from(user: $0, stats: viewModel.userStats)
            }
        )
        .task { await viewModel.onAppear() }
    }

    // MARK: - ═══════ الخلفية ═══════

    private var background: some View {
        ZStack {
            // التدرج الرئيسي
            LinearGradient(
                colors: [Color(hex: "08091E"), Color(hex: "12103B"), Color(hex: "0B0A24")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // نمط هندسي خافت
            GeometryReader { geo in
                Canvas { context, size in
                    // نجوم
                    for _ in 0..<70 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let s = CGFloat.random(in: 0.5...2)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)),
                            with: .color(.white.opacity(Double.random(in: 0.05...0.25)))
                        )
                    }
                }

                // هالة ذهبية خلف البطاقات الرئيسية
                RadialGradient(
                    colors: [Color(hex: "FFD700").opacity(0.06), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: geo.size.width * 0.6
                )
                .offset(y: -geo.size.height * 0.15)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - ═══════ الشريط العلوي ═══════

    private var topBar: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            // الأفاتار + الاسم → بطاقة اللاعب (popup)
            Button { showPlayerCard = true } label: {
                HStack(spacing: AppSizes.Spacing.sm) {
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: authManager.currentUser?.fullAvatarUrl ?? "")) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.gray)
                        }
                        .frame(width: 46, height: 46)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(tierColor, lineWidth: 2))

                        Text(tierEmoji)
                            .font(.system(size: 10))
                            .frame(width: 16, height: 16)
                            .background(Color(hex: "0E1236"))
                            .clipShape(Circle())
                            .offset(x: 3, y: 3)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(authManager.currentUser?.username ?? "محارب")
                            .font(.cairo(.bold, size: AppSizes.Font.body))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text("\(AppStrings.Main.level) \(authManager.currentUser?.level ?? 1)")
                            .font(.cairo(.medium, size: 10))
                            .foregroundStyle(tierColor)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // الذهب
            Button { showStore = true } label: {
                HStack(spacing: 4) {
                    Text("🪙").font(.system(size: 14))
                    Text("\(authManager.currentUser?.gold ?? 0)")
                        .font(.poppins(.bold, size: 12))
                        .foregroundStyle(Color(hex: "FFD700"))
                }
                .padding(.horizontal, AppSizes.Spacing.xs)
                .padding(.vertical, 4)
                .background(Color(hex: "FFD700").opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "FFD700").opacity(0.2), lineWidth: 1))
            }

            // الجواهر
            Button { showStore = true } label: {
                HStack(spacing: 4) {
                    Image("icon_gem").resizable().scaledToFit().frame(width: 14, height: 14)
                    Text("\(authManager.currentUser?.gems ?? 0)")
                        .font(.poppins(.bold, size: 12))
                        .foregroundStyle(Color(hex: "60A5FA"))
                }
                .padding(.horizontal, AppSizes.Spacing.xs)
                .padding(.vertical, 4)
                .background(Color(hex: "60A5FA").opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "60A5FA").opacity(0.2), lineWidth: 1))
            }

            // شارة عشيرتي (وصول مباشر)
            if let clan = clanState.myClan {
                clanTopBarBadge(clan)
            }

            // الإشعارات
            iconBadge("bell.fill", count: viewModel.unreadCount) { showNotifications = true }
            // الإعدادات
            iconBtn("gearshape.fill") { showProfile = true }
        }
    }

    // MARK: - شارة العشيرة في الـ TopBar
    private func clanTopBarBadge(_ clan: Clan) -> some View {
        Button {
            HapticManager.light()
            directClanId = clan.id
        } label: {
            ZStack(alignment: .topLeading) {
                ZStack {
                    Circle()
                        .fill(clan.displayColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Circle()
                        .strokeBorder(clan.displayColor.opacity(0.5), lineWidth: 1)
                        .frame(width: 34, height: 34)
                    Image(systemName: clanBadgeIcon(clan.badge))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(clan.displayColor)
                }
                if clanState.unreadCount > 0 {
                    Text("\(min(clanState.unreadCount, 9))\(clanState.unreadCount > 9 ? "+" : "")")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 14, minHeight: 14)
                        .padding(.horizontal, 2)
                        .background(AppColors.Default.error)
                        .clipShape(Capsule())
                        .offset(x: -2, y: -2)
                }
            }
        }
    }

    private func clanBadgeIcon(_ badge: String?) -> String {
        switch (badge ?? "").lowercased() {
        case "eagle":  return "bird.fill"
        case "lion":   return "pawprint.fill"
        case "shield": return "shield.fill"
        case "sword":  return "bolt.shield.fill"
        case "crown":  return "crown.fill"
        case "star":   return "star.fill"
        case "flame":  return "flame.fill"
        default:       return "flag.fill"
        }
    }

    // MARK: شريط XP
    // MARK: - ═══════ البطاقتين الرئيسيتين ═══════

    private var mainCards: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            heroCard(
                mode: .random1v1,
                bg: LinearGradient(
                    colors: [Color(hex: "2A1F00"), Color(hex: "4A3800"), Color(hex: "1A1200")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                border: [Color(hex: "FFD700"), Color(hex: "B8860B")],
                glow: Color(hex: "FFD700")
            )

            heroCard(
                mode: .random4,
                bg: LinearGradient(
                    colors: [Color(hex: "2A1F00"), Color(hex: "3D2E00"), Color(hex: "1A1200")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                border: [Color(hex: "DAA520"), Color(hex: "8B6914")],
                glow: Color(hex: "DAA520")
            )
        }
    }

    private func heroCard(mode: GameMode, bg: LinearGradient, border: [Color], glow: Color) -> some View {
        Button {
            HapticManager.medium()
            viewModel.selectMode(mode)
        } label: {
            VStack(spacing: AppSizes.Spacing.md) {
                Image(mode.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .shadow(color: glow.opacity(0.7), radius: 15)

                Text(mode.title)
                    .font(.cairo(.black, size: AppSizes.Font.title1))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                    .stroke(
                        LinearGradient(colors: [border[0].opacity(0.6), border[1].opacity(0.15)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
            )
            .shadow(color: glow.opacity(0.12), radius: 20, y: 8)
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
                        .fill(
                            RadialGradient(
                                colors: [AppColors.Default.goldPrimary.opacity(0.2), .clear],
                                center: .center, startRadius: 5, endRadius: 28
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(mode.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }

                Text(mode.title)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)

                Text(mode.subtitle)
                    .font(.cairo(.regular, size: 10))
                    .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.md)
            .background(Color(hex: "12103B").opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(AppColors.Default.goldPrimary.opacity(0.15), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - ═══════ الإجراءات السريعة ═══════

    private var quickActions: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            // صف 1: مكافأة + عجلة + كود
            HStack(spacing: AppSizes.Spacing.md) {
                actionBtn(icon: "gift.fill", title: AppStrings.Main.dailyReward,
                          color: Color(hex: "FFD700"), badge: viewModel.canClaimDaily) {
                    showDailyReward = true
                }

                actionBtn(icon: "arrow.trianglehead.2.counterclockwise.rotate.90",
                          title: AppStrings.Main.spinWheel,
                          color: Color(hex: "DAA520"), badge: viewModel.canSpin) {
                    showSpinWheel = true
                }

                actionBtn(icon: "keyboard", title: AppStrings.Main.joinRoom,
                          color: Color(hex: "C9A227"), badge: false) {
                    viewModel.showJoinRoom = true
                }
            }

            // صف 2: متجر + متصدرين + أصدقاء
            HStack(spacing: AppSizes.Spacing.md) {
                actionBtn(icon: "bag.fill", title: "المتجر",
                          color: Color(hex: "8B5CF6"), badge: false) {
                    showStore = true
                }

                actionBtn(icon: "trophy.fill", title: "المتصدرين",
                          color: Color(hex: "F59E0B"), badge: false) {
                    showLeaderboard = true
                }

                actionBtn(icon: "person.2.fill", title: "الأصدقاء",
                          color: Color(hex: "22C55E"), badge: false) {
                    showFriends = true
                }
            }

            // صف 3: العشائر (زر ذكي)
            smartClanButton
        }
    }

    // MARK: - الزر الذكي للعشائر
    @ViewBuilder
    private var smartClanButton: some View {
        if let clan = clanState.myClan {
            // عنده عشيرة → Detail مباشرة + معلومات العشيرة
            Button {
                HapticManager.medium()
                directClanId = clan.id
            } label: {
                HStack(spacing: AppSizes.Spacing.sm) {
                    ZStack(alignment: .topTrailing) {
                        ClanBadgeView(badge: clan.badge, color: clan.displayColor, size: 38)
                        if clanState.unreadCount > 0 {
                            Text("\(min(clanState.unreadCount, 9))\(clanState.unreadCount > 9 ? "+" : "")")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .padding(.horizontal, 3)
                                .background(AppColors.Default.error)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(clan.name)
                                .font(.cairo(.bold, size: AppSizes.Font.body))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            if let role = clan.myRole {
                                Image(systemName: role.icon)
                                    .font(.system(size: 9))
                                    .foregroundStyle(role.color)
                            }
                        }
                        HStack(spacing: 6) {
                            Label("Lv.\(clan.level)", systemImage: "shield.lefthalf.filled")
                                .labelStyle(.titleAndIcon)
                                .font(.poppins(.semiBold, size: 9))
                                .foregroundStyle(clan.displayColor)
                            Text("•").foregroundStyle(.white.opacity(0.2))
                            Text("\(clan.memberCount ?? 0) عضو")
                                .font(.cairo(.medium, size: 10))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, AppSizes.Spacing.md)
                .padding(.vertical, AppSizes.Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [clan.displayColor.opacity(0.15), clan.displayColor.opacity(0.03)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                        .stroke(clan.displayColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        } else {
            // ما عنده عشيرة → Hub
            actionBtn(icon: "shield.lefthalf.filled",
                      title: "انضم إلى عشيرة",
                      color: Color(hex: "FFD700"), badge: false) {
                showClans = true
            }
        }
    }

    private func actionBtn(icon: String, title: String, color: Color, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { HapticManager.light(); action() }) {
            VStack(spacing: AppSizes.Spacing.sm) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                    if badge {
                        Circle().fill(AppColors.Default.error).frame(width: 8, height: 8).offset(x: -4, y: -4)
                    }
                }
                Text(title)
                    .font(.cairo(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.md)
            .background(color.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - ═══════ Helpers ═══════

    private func iconBtn(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.05))
                .clipShape(Circle())
        }
    }

    private func iconBadge(_ name: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                Image(systemName: name)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.05))
                    .clipShape(Circle())
                if count > 0 {
                    Text("\(min(count, 9))")
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

    // MARK: رتبة اللاعب
    private var tierColor: Color {
        let level = authManager.currentUser?.level ?? 1
        switch level {
        case 1...5:   return AppColors.Tier.bronze
        case 6...15:  return AppColors.Tier.silver
        case 16...30: return AppColors.Tier.gold
        case 31...50: return AppColors.Tier.platinum
        default:      return AppColors.Tier.diamond
        }
    }

    private var tierEmoji: String {
        let level = authManager.currentUser?.level ?? 1
        switch level {
        case 1...5:   return "🥉"
        case 6...15:  return "🥈"
        case 16...30: return "🥇"
        case 31...50: return "💎"
        default:      return "👑"
        }
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
