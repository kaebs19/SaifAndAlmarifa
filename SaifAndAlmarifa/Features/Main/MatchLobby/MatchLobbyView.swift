//
//  MatchLobbyView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Main/MatchLobby/MatchLobbyView.swift
//  شاشة اللعب الموحّدة — تعمل لجميع الأوضاع الخمسة:
//  عشوائي، ضد 4، ضد شخص (غرفة)، ضد صديق، ضد أصدقائي

import SwiftUI

// MARK: - الشاشة الرئيسية
struct MatchLobbyView: View {

    let mode: GameMode
    @ObservedObject var viewModel: MainViewModel

    @State private var elapsed = 0
    @State private var timer: Timer?
    @State private var pulse = false
    @State private var showFriendPicker: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showInviteSheet: Bool = false
    @State private var showQRSheet: Bool = false
    @State private var copiedPulse: Bool = false

    var body: some View {
        ZStack {
            background

            // Countdown Overlay (يطغى على كل شي)
            if let count = viewModel.roomCountdown {
                countdownOverlay(count: count)
                    .zIndex(10)
            }

            // Copy animation overlay
            if copiedPulse {
                copiedToast
                    .zIndex(9)
                    .transition(.scale.combined(with: .opacity))
            }

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSizes.Spacing.lg) {
                        modeHeader
                        modeDetails

                        switch currentState {
                        case .creating:
                            creatingRoomSection
                        case .roomReady:
                            roomReadySection
                        case .searching:
                            searchingSection
                        case .matchFound:
                            matchFoundSection
                        }
                    }
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.top, AppSizes.Spacing.md)
                    .padding(.bottom, AppSizes.Spacing.xxl)
                }

                bottomBar
            }
        }
        .onAppear {
            startTimer()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showShareSheet) {
            if let code = viewModel.roomCode {
                ShareSheet(activityItems: [viewModel.shareMessage()])
                    .presentationDetents([.medium])
                    .onAppear { _ = code }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteFriendsSheet(viewModel: viewModel, mode: mode)
                .presentationDetents([.large])
                .withToast()
        }
        .sheet(isPresented: $showQRSheet) {
            if let code = viewModel.roomCode {
                RoomQRSheet(
                    code: code,
                    shareLink: viewModel.roomShareLink,
                    modeName: mode.title
                )
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - Countdown Overlay
    private func countdownOverlay(count: Int) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: AppSizes.Spacing.md) {
                Text("🎉 الغرفة جاهزة!")
                    .font(.cairo(.black, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)

                Text("\(count)")
                    .font(.poppins(.black, size: 140))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "DAA520")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: AppColors.Default.goldPrimary.opacity(0.8), radius: 30)
                    .scaleEffect(pulse ? 1.1 : 0.9)
                    .id(count)  // تتغيّر مع كل تحديث لتشغيل scale animation

                Text("جاري بدء المباراة...")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
    }

    // MARK: - Copied Toast
    private var copiedToast: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.Default.success)
            Text("تم النسخ!")
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
        }
        .padding(AppSizes.Spacing.lg)
        .background(.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - الحالة الحالية
    private enum LobbyState { case creating, roomReady, searching, matchFound }

    private var currentState: LobbyState {
        if viewModel.matchFoundId != nil { return .matchFound }
        if mode.isQueue { return .searching }
        if viewModel.roomCode != nil { return .roomReady }
        return .creating
    }

    // MARK: - خلفية
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "08091E"), Color(hex: "12103B"), Color(hex: "0B0A24")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // هالة الوضع
            RadialGradient(
                colors: [mode.accentColor.opacity(0.2), .clear],
                center: .top, startRadius: 20, endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button { viewModel.closeLobby() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Text(mode.title)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)
            Spacer()
            // مكان مقابل للـ X لعمل توازن
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(AppSizes.Spacing.lg)
    }

    // MARK: - عنوان الوضع + أيقونة
    private var modeHeader: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [mode.accentColor.opacity(0.4), mode.accentColor.opacity(0.05)],
                            center: .center, startRadius: 10, endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(mode.accentColor.opacity(pulse ? 0.8 : 0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulse ? 1.1 : 1.0)

                Image(mode.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .shadow(color: mode.accentColor.opacity(0.7), radius: 12)
            }

            Text(mode.subtitle)
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - تفاصيل الوضع (3 بطاقات)
    private var modeDetails: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            ForEach(Array(mode.details.enumerated()), id: \.offset) { _, d in
                detailPill(icon: d.icon, label: d.label, value: d.value)
            }
        }
    }

    private func detailPill(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(mode.accentColor)
            Text(value)
                .font(.poppins(.bold, size: 16))
                .foregroundStyle(.white)
            Text(label)
                .font(.cairo(.regular, size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(mode.accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(mode.accentColor.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - قسم جاري البحث (Random)
    private var searchingSection: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // Dots animation
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(mode.accentColor)
                        .frame(width: 10, height: 10)
                        .scaleEffect(pulse ? 1.3 : 0.6)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: pulse
                        )
                }
            }

            Text("جاري البحث عن \(mode == .random4 ? "لاعبين" : "خصم")")
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(.white)

            Text(elapsedText)
                .font(.poppins(.bold, size: 18))
                .foregroundStyle(mode.accentColor)
                .monospacedDigit()

            rewardPreview
        }
        .padding(AppSizes.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
    }

    // MARK: - قسم الغرفة قيد الإنشاء
    private var creatingRoomSection: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            ProgressView().tint(mode.accentColor)
            Text("جاري إنشاء الغرفة...")
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(AppSizes.Spacing.lg)
        .frame(maxWidth: .infinity)
    }

    private var friendsSection: some View {
        Group {
            if viewModel.friends.isEmpty {
                VStack(spacing: AppSizes.Spacing.sm) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("لا يوجد أصدقاء بعد")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("شارك الكود بطريقة أخرى")
                        .font(.cairo(.regular, size: AppSizes.Font.caption))
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: AppSizes.Spacing.sm) {
                        Button {
                            HapticManager.light()
                            showShareSheet = true
                        } label: {
                            Label("مشاركة خارجية", systemImage: "square.and.arrow.up")
                                .font(.cairo(.semiBold, size: 11))
                                .foregroundStyle(.white)
                                .padding(.horizontal, AppSizes.Spacing.sm)
                                .padding(.vertical, 8)
                                .background(Color(hex: "60A5FA"))
                                .clipShape(Capsule())
                        }

                        if ClanStateManager.shared.myClan != nil {
                            Button {
                                Task { await viewModel.shareRoomCodeToClan() }
                            } label: {
                                Label("لعشيرتي", systemImage: "shield.lefthalf.filled")
                                    .font(.cairo(.semiBold, size: 11))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, AppSizes.Spacing.sm)
                                    .padding(.vertical, 8)
                                    .background(AppColors.Default.goldPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(AppSizes.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.friends) { friend in
                        friendRow(friend)
                    }
                }
            }
        }
    }

    private func friendRow(_ friend: Friend) -> some View {
        let isSelected = viewModel.invitedFriends.contains(where: { $0.id == friend.id })
        let maxReached = !isSelected && viewModel.invitedFriends.count >= (mode.playersRequired - 1)

        return Button {
            HapticManager.selection()
            if isSelected {
                viewModel.uninviteFriend(friend)
            } else if !maxReached {
                viewModel.inviteFriend(friend)
            }
        } label: {
            HStack(spacing: AppSizes.Spacing.sm) {
                AvatarView(imageURL: friend.avatarUrl, size: 40,
                           showOnlineIndicator: true,
                           isOnline: friend.isOnline ?? false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.username)
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                    Text(friend.isOnline == true ? "متصل" : "غير متصل")
                        .font(.cairo(.regular, size: 10))
                        .foregroundStyle(friend.isOnline == true ? AppColors.Default.success : .white.opacity(0.3))
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColors.Default.success : (maxReached ? .white.opacity(0.2) : mode.accentColor))
            }
            .padding(AppSizes.Spacing.sm)
            .background(isSelected ? mode.accentColor.opacity(0.1) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(isSelected ? mode.accentColor.opacity(0.4) : .white.opacity(0.06), lineWidth: 1)
            )
            .opacity(maxReached ? 0.4 : 1)
        }
        .disabled(maxReached)
    }

    // MARK: - قسم الغرفة جاهزة (بعد إنشائها)
    private var roomReadySection: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // كود الغرفة
            VStack(spacing: 6) {
                Text("كود الغرفة")
                    .font(.cairo(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                Text(viewModel.roomCode ?? "----")
                    .font(.poppins(.black, size: 32))
                    .foregroundStyle(mode.accentColor)
                    .tracking(6)
            }
            .padding(.vertical, AppSizes.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(mode.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(mode.accentColor.opacity(0.3), lineWidth: 1)
            )

            // أزرار المشاركة
            shareButtonsRow

            // اللاعبون في الغرفة
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("اللاعبون (\(viewModel.roomPlayers.count + 1)/\(mode.playersRequired))",
                          systemImage: "person.2.fill")
                        .font(.cairo(.bold, size: AppSizes.Font.caption))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
                // أنا (المضيف)
                meSlot
                // اللاعبون الآخرون
                ForEach(viewModel.roomPlayers) { player in
                    playerSlot(player: player)
                }
                // Slots فارغة
                ForEach(0..<max(0, mode.playersRequired - 1 - viewModel.roomPlayers.count), id: \.self) { _ in
                    emptySlot
                }
            }

            // الأصدقاء المدعوين
            if !viewModel.invitedFriends.isEmpty && viewModel.roomPlayers.count < (mode.playersRequired - 1) {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 11))
                    Text("الدعوات مُرسَلة لـ \(viewModel.invitedFriends.count) صديق")
                        .font(.cairo(.medium, size: 11))
                }
                .foregroundStyle(.white.opacity(0.5))
            }

            // زر "+ إضافة صديق" — إذا فيه slots فاضية
            if canInviteMore {
                Button {
                    HapticManager.light()
                    showInviteSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus.fill")
                        Text("فتح قائمة الأصدقاء")
                    }
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(mode.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .background(mode.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                            .stroke(mode.accentColor.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            rewardPreview
        }
    }

    /// هل يقدر يدعو مزيد؟
    private var canInviteMore: Bool {
        let currentCount = 1 + viewModel.roomPlayers.count + viewModel.invitedFriends.count
        return currentCount < mode.playersRequired
    }

    // MARK: - أزرار المشاركة (نسخ / QR / share / عشيرة)
    private var shareButtonsRow: some View {
        HStack(spacing: AppSizes.Spacing.xs) {
            // نسخ
            shareButton(
                icon: "doc.on.doc.fill",
                label: "نسخ",
                color: AppColors.Default.goldPrimary
            ) {
                UIPasteboard.general.string = viewModel.roomCode
                HapticManager.success()
                // Animation overlay
                withAnimation(.spring()) { copiedPulse = true }
                Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    withAnimation { copiedPulse = false }
                }
            }

            // QR Code
            shareButton(
                icon: "qrcode",
                label: "QR",
                color: Color(hex: "A78BFA")
            ) {
                HapticManager.light()
                showQRSheet = true
            }

            // مشاركة (iOS Share Sheet)
            shareButton(
                icon: "square.and.arrow.up.fill",
                label: "مشاركة",
                color: Color(hex: "60A5FA")
            ) {
                HapticManager.light()
                showShareSheet = true
            }

            // إرسال لعشيرتي (إذا في عشيرة)
            if ClanStateManager.shared.myClan != nil {
                shareButton(
                    icon: "shield.lefthalf.filled",
                    label: "عشيرتي",
                    color: Color(hex: "FFD700")
                ) {
                    Task { await viewModel.shareRoomCodeToClan() }
                }
            }
        }
    }

    private func shareButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                Text(label)
                    .font(.cairo(.semiBold, size: 10))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.sm)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // Slot لي (المضيف) — يستخدم أفاتار من AuthManager
    private var meSlot: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            AvatarView(imageURL: viewModel.user?.avatarUrl, size: 36)
                .overlay(
                    Circle().stroke(AppColors.Default.goldPrimary, lineWidth: 2)
                )
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("أنت")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                    Text("👑")
                        .font(.system(size: 13))
                    if let username = viewModel.user?.username {
                        Text("(\(username))")
                            .font(.cairo(.regular, size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                if let lvl = viewModel.user?.level {
                    Text("Lv.\(lvl) • المضيف")
                        .font(.poppins(.medium, size: 10))
                        .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.7))
                }
            }
            Spacer()
            readyBadge(isReady: viewModel.amIReady)
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, 6)
        .background(AppColors.Default.goldPrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    // Slot للاعب آخر — من RoomPlayer
    private func playerSlot(player: RoomPlayer) -> some View {
        let isReady = viewModel.readyUserIds.contains(player.id)
        let canKick = amIHost && !mode.isQueue

        return HStack(spacing: AppSizes.Spacing.sm) {
            AvatarView(imageURL: player.avatarUrl, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(player.username)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let lvl = player.level {
                    Text("Lv.\(lvl)")
                        .font(.poppins(.medium, size: 10))
                        .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.7))
                }
            }
            Spacer()
            readyBadge(isReady: isReady)

            if canKick {
                Menu {
                    Button(role: .destructive) {
                        viewModel.kick(player)
                    } label: {
                        Label("طرد من الغرفة", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 28, height: 28)
                }
            }
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, 6)
        .background(isReady ? AppColors.Default.success.opacity(0.08) : Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isReady ? AppColors.Default.success.opacity(0.3) : .white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }

    /// هل أنا الهوست؟ (أول من أنشأ الغرفة = أنا دائماً في iOS)
    private var amIHost: Bool { true }

    private func readyBadge(isReady: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 9))
            Text(isReady ? "جاهز" : "ينتظر")
        }
        .font(.cairo(.semiBold, size: 10))
        .foregroundStyle(isReady ? AppColors.Default.success : .white.opacity(0.4))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background((isReady ? AppColors.Default.success : Color.gray).opacity(0.15))
        .clipShape(Capsule())
    }

    // Slot فارغ — قابل للضغط لدعوة صديق
    private var emptySlot: some View {
        Button {
            HapticManager.light()
            showInviteSheet = true
        } label: {
            HStack(spacing: AppSizes.Spacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(mode.accentColor.opacity(0.4),
                                      style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(mode.accentColor.opacity(0.7))
                }
                Text("دعوة لاعب")
                    .font(.cairo(.semiBold, size: AppSizes.Font.body))
                    .foregroundStyle(mode.accentColor.opacity(0.8))
                Spacer()
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 14))
                    .foregroundStyle(mode.accentColor.opacity(0.5))
            }
            .padding(.horizontal, AppSizes.Spacing.sm)
            .padding(.vertical, 6)
            .background(mode.accentColor.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(mode.accentColor.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Match Found
    private var matchFoundSection: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.Default.success)
            Text("تم إيجاد مباراة!")
                .font(.cairo(.black, size: AppSizes.Font.title2))
                .foregroundStyle(.white)
            Text("جاري الانتقال للعبة...")
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(AppSizes.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppColors.Default.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - معاينة الجوائز
    private var rewardPreview: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            reward(icon: "trophy.fill", label: "فوز", value: "+\(mode.winReward)", color: Color(hex: "FFD700"))
            reward(icon: "heart.slash", label: "خسارة", value: "+\(mode.loseReward)", color: .gray)
        }
    }

    private func reward(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.poppins(.bold, size: 13)).foregroundStyle(color)
            Text(label).font(.cairo(.regular, size: 11)).foregroundStyle(.white.opacity(0.4))
            Text("🪙").font(.system(size: 11))
        }
        .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 6)
        .background(color.opacity(0.06))
        .clipShape(Capsule())
    }

    // MARK: - Bottom Bar (الزر السفلي)
    @ViewBuilder
    private var bottomBar: some View {
        switch currentState {
        case .matchFound:
            EmptyView()
        case .searching:
            cancelButton("إلغاء البحث")
        case .roomReady:
            VStack(spacing: 0) {
                // شات الغرفة (expandable)
                RoomChatBar(viewModel: viewModel)

                HStack(spacing: AppSizes.Spacing.sm) {
                    // زر الاستعداد
                    Button {
                        viewModel.toggleReady()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.amIReady ? "checkmark.circle.fill" : "hand.raised.fill")
                            Text(viewModel.amIReady ? "جاهز ✓" : "اضغط للاستعداد")
                        }
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(viewModel.amIReady ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSizes.Spacing.sm)
                        .background(viewModel.amIReady ? AppColors.Default.success : AppColors.Default.goldPrimary)
                        .clipShape(Capsule())
                    }

                    cancelButton("إلغاء").frame(width: 100)
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.bottom, AppSizes.Spacing.md)
                .padding(.top, AppSizes.Spacing.xs)
            }
        case .creating:
            cancelButton("إلغاء")
        }
    }

    private func cancelButton(_ title: String) -> some View {
        Button {
            HapticManager.warning()
            viewModel.closeLobby()
        } label: {
            Text(title)
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSizes.Spacing.md)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1)
                )
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.bottom, AppSizes.Spacing.md)
    }

    // MARK: - Helpers
    private var elapsedText: String {
        String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }

    private func startTimer() {
        timer?.invalidate()
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in elapsed += 1 }
        }
    }
}

// MARK: - iOS Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
