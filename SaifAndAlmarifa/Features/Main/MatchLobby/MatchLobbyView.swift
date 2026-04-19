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

    var body: some View {
        ZStack {
            background

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
            // افتح قائمة الأصدقاء تلقائياً لو الوضع يحتاج أصدقاء
            if mode.needsFriend {
                showFriendPicker = true
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
                        .font(.cairo(.medium, size: AppSizes.Font.body))
                        .foregroundStyle(.white.opacity(0.5))
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
                    Task { await viewModel.loadFriends() }
                    withAnimation { showFriendPicker.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showFriendPicker ? "chevron.up" : "plus.circle.fill")
                        Text(showFriendPicker ? "إخفاء القائمة" : "دعوة صديق من القائمة")
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

            if showFriendPicker {
                friendsSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            rewardPreview
        }
    }

    /// هل يقدر يدعو مزيد؟
    private var canInviteMore: Bool {
        let currentCount = 1 + viewModel.roomPlayers.count + viewModel.invitedFriends.count
        return currentCount < mode.playersRequired
    }

    // MARK: - أزرار المشاركة (نسخ / share / عشيرة)
    private var shareButtonsRow: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            // نسخ
            shareButton(
                icon: "doc.on.doc.fill",
                label: "نسخ",
                color: AppColors.Default.goldPrimary
            ) {
                UIPasteboard.general.string = viewModel.roomCode
                HapticManager.success()
                ToastManager.shared.info("تم النسخ")
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
        slotRow(
            avatarUrl: viewModel.user?.avatarUrl,
            name: viewModel.user?.username ?? "أنت",
            level: viewModel.user?.level,
            isHost: true
        )
    }

    // Slot للاعب آخر — من RoomPlayer
    private func playerSlot(player: RoomPlayer) -> some View {
        slotRow(
            avatarUrl: player.avatarUrl,
            name: player.username,
            level: player.level,
            isHost: false
        )
    }

    // مكوّن موحّد
    private func slotRow(avatarUrl: String?, name: String, level: Int?, isHost: Bool) -> some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            AvatarView(imageURL: avatarUrl, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if isHost {
                        Text("👑")
                            .font(.system(size: 10))
                    }
                }
                if let lvl = level {
                    Text("Lv.\(lvl)")
                        .font(.poppins(.medium, size: 10))
                        .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.7))
                }
            }
            Spacer()
            Text("جاهز")
                .font(.cairo(.semiBold, size: 10))
                .foregroundStyle(AppColors.Default.success)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(AppColors.Default.success.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, 6)
        .background(AppColors.Default.success.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.Default.success.opacity(0.15), lineWidth: 1)
        )
    }

    private var emptySlot: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Circle().strokeBorder(.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(width: 36, height: 36)
            Text("في انتظار لاعب...")
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
            TypingDots()
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            HStack(spacing: AppSizes.Spacing.sm) {
                // إشارة "في انتظار اللاعبين"
                Text("في انتظار اللاعبين...")
                    .font(.cairo(.medium, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                cancelButton("إلغاء").frame(width: 110)
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.md)
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
