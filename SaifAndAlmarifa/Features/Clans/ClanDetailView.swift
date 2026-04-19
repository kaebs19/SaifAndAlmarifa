//
//  ClanDetailView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/ClanDetailView.swift
//  شاشة تفاصيل عشيرة مع تابات (شات / أعضاء / ترتيب / طلبات / معلومات)

import SwiftUI

struct ClanDetailView: View {

    @StateObject private var viewModel: ClanDetailViewModel
    @StateObject private var clanState = ClanStateManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showLeaveConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showClearChatConfirm = false
    @State private var showDonateSheet = false
    @State private var reportingMessage: ClanMessage?
    @State private var muteTarget: ClanMember?
    @State private var joinInFlight = false

    var onClose: () -> Void

    init(clanId: String, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ClanDetailViewModel(clanId: clanId))
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let clan = viewModel.clan {
                clanBanner(clan)
                ClanTabBar(tabs: viewModel.availableTabs, selection: $viewModel.selectedTab)
                    .padding(.top, AppSizes.Spacing.sm)

                TabView(selection: $viewModel.selectedTab) {
                    chatTab.tag(0)
                    statsTab.tag(1)
                    leaderboardTab.tag(2)
                    membersTab.tag(3)
                    ClanWarsTab(war: viewModel.currentWar, isLoading: viewModel.isLoading).tag(4)
                    ClanTreasuryTab(
                        treasury: clan.treasury ?? 0,
                        history: viewModel.treasuryHistory,
                        myGold: AuthManager.shared.currentUser?.gold ?? 0,
                        onDonate: { showDonateSheet = true }
                    ).tag(5)
                    ClanPerksTab(clanLevel: clan.level).tag(6)
                    ClanHistoryTab(events: viewModel.events, isLoading: viewModel.isLoading).tag(7)
                    if viewModel.canManage { requestsTab.tag(8) }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else if viewModel.isLoading {
                SkeletonList(count: 6).padding(.top, AppSizes.Spacing.lg)
                Spacer()
            } else {
                Spacer()
                ClanEmptyState(icon: "exclamationmark.triangle", title: "تعذّر تحميل العشيرة")
                Spacer()
            }
        }
        .background(GradientBackground.main)
        .withToast()
        .task { await viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: viewModel.didLeave) { _, left in
            if left { onClose() }
        }
        .confirmationDialog("هل تريد مغادرة العشيرة؟", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
            Button("مغادرة", role: .destructive) { Task { await viewModel.leave() } }
            Button("إلغاء", role: .cancel) {}
        }
        .confirmationDialog("حذف العشيرة نهائياً؟", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("حذف", role: .destructive) { Task { await viewModel.deleteClan() } }
            Button("إلغاء", role: .cancel) {}
        }
        .confirmationDialog("مسح كل الرسائل؟", isPresented: $showClearChatConfirm, titleVisibility: .visible) {
            Button("مسح الكل", role: .destructive) { Task { await viewModel.clearAllChat() } }
            Button("إلغاء", role: .cancel) {}
        }
        .sheet(item: $reportingMessage) { msg in
            ReportReasonSheet(message: msg) { reason in
                Task { await viewModel.reportMessage(msg, reason: reason) }
                reportingMessage = nil
            }
            .presentationDetents([.height(320)])
        }
        .sheet(item: $muteTarget) { member in
            MuteMemberSheet(member: member) { minutes in
                Task { await viewModel.mute(member, durationMinutes: minutes) }
                muteTarget = nil
            }
            .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $showDonateSheet) {
            TreasuryDonateSheet(myGold: AuthManager.shared.currentUser?.gold ?? 0) { amount in
                Task {
                    if await viewModel.donate(amount: amount) { showDonateSheet = false }
                }
            }
            .presentationDetents([.height(480)])
        }
    }

    // MARK: - Header
    private var header: some View {
        ZStack {
            Text(viewModel.clan?.name ?? "عشيرة")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)
                .lineLimit(1)
            HStack {
                Button { onClose() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                if viewModel.isMember {
                    Menu {
                        // أدوات الإدارة (للزعيم فقط)
                        if viewModel.isOwner, let clan = viewModel.clan {
                            Section("أدوات الإدارة") {
                                Button {
                                    Task { await viewModel.toggleReadOnly() }
                                } label: {
                                    Label(
                                        (clan.readOnly ?? false) ? "تعطيل وضع الإعلانات فقط" : "تفعيل وضع الإعلانات فقط",
                                        systemImage: (clan.readOnly ?? false) ? "speaker.wave.2" : "megaphone"
                                    )
                                }
                                Button(role: .destructive) {
                                    showClearChatConfirm = true
                                } label: {
                                    Label("مسح كل الرسائل", systemImage: "trash.slash")
                                }
                            }
                        }

                        if viewModel.isOwner {
                            Button(role: .destructive) { showDeleteConfirm = true } label: {
                                Label("حذف العشيرة", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive) { showLeaveConfirm = true } label: {
                                Label("مغادرة", systemImage: "arrow.right.square")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(AppSizes.Spacing.lg)
    }

    // MARK: - بانر العشيرة
    private func clanBanner(_ clan: Clan) -> some View {
        HStack(spacing: AppSizes.Spacing.md) {
            ClanBadgeView(badge: clan.badge, color: clan.displayColor, size: 64)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Lv.\(clan.level)")
                        .font(.poppins(.bold, size: 11))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(clan.displayColor)
                        .clipShape(Capsule())
                    Text("\(clan.memberCount ?? 0)/\(clan.maxMembers ?? 30) عضو")
                        .font(.cairo(.medium, size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    if clan.isOpen == false {
                        Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                    }
                }

                // شريط التقدم للمستوى
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.08)).frame(height: 4)
                        Capsule()
                            .fill(clan.displayColor)
                            .frame(width: geo.size.width * clan.levelProgress, height: 4)
                    }
                }
                .frame(height: 4)

                if let desc = clan.description, !desc.isEmpty {
                    Text(desc)
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }
            }

            Spacer()

            // زر انضمام لو مو عضو
            if !viewModel.isMember {
                Button {
                    Task {
                        joinInFlight = true
                        await viewModel.join()
                        joinInFlight = false
                    }
                } label: {
                    Text(joinInFlight ? "..." : (clan.isOpen == false ? "طلب انضمام" : "انضمام"))
                        .font(.cairo(.bold, size: 11))
                        .foregroundStyle(.black)
                        .padding(.horizontal, AppSizes.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(AppColors.Default.goldPrimary)
                        .clipShape(Capsule())
                }
                .disabled(joinInFlight)
            }
        }
        .padding(AppSizes.Spacing.md)
        .background(
            LinearGradient(
                colors: [clan.displayColor.opacity(0.15), clan.displayColor.opacity(0.02)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(clan.displayColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    // MARK: - Chat Tab
    private var chatTab: some View {
        VStack(spacing: 0) {
            if viewModel.messages.isEmpty {
                ClanEmptyState(icon: "bubble.left", title: "لا توجد رسائل", subtitle: "كن أول من يبدأ المحادثة")
                    .frame(maxHeight: .infinity)
            } else {
                chatMessagesList
            }

            if viewModel.isMember {
                if viewModel.canSendMessages {
                    chatInputBar
                } else {
                    sendBlockedBar
                }
            }
        }
    }

    // MARK: - شريط "غير مسموح بالإرسال"
    private var sendBlockedBar: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Image(systemName: viewModel.myMemberRecord?.isMuted == true ? "mic.slash.fill" : "megaphone.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.Default.warning)
            Text(viewModel.sendBlockedReason ?? "غير مسموح")
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(AppSizes.Spacing.md)
        .background(AppColors.Default.warning.opacity(0.08))
        .overlay(
            Rectangle().fill(AppColors.Default.warning.opacity(0.3)).frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - قائمة الرسائل مع فواصل التاريخ
    private var chatMessagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Trigger: Load more عند الوصول للأعلى (الأقدم)
                    if viewModel.hasMoreMessages && !viewModel.messages.isEmpty {
                        Group {
                            if viewModel.isLoadingMore {
                                ProgressView().tint(.white.opacity(0.5))
                                    .padding(.vertical, AppSizes.Spacing.sm)
                            } else {
                                Color.clear.frame(height: 1)
                                    .onAppear { Task { await viewModel.loadMoreMessages() } }
                            }
                        }
                    }

                    // السيرفر يرجع الأحدث أولاً → نعكس ليصير الأحدث أسفل
                    let ordered = viewModel.messages.reversed()
                    ForEach(Array(ordered.enumerated()), id: \.element.id) { idx, msg in
                        // فاصل التاريخ
                        if shouldShowDateSeparator(current: msg, previousIndex: idx, all: Array(ordered)) {
                            if let d = msg.date {
                                ChatDateSeparator(label: ChatDateFormat.dayLabel(for: d))
                            }
                        }

                        ClanMessageBubble(
                            message: msg,
                            isMine: msg.user?.id == viewModel.myId,
                            showTimestamp: viewModel.tappedMessageId == msg.id,
                            onReaction: { emoji in
                                Task { await viewModel.react(to: msg, emoji: emoji) }
                            },
                            onJoinRoom: { code in
                                AppSocketManager.shared.joinRoom(code: code)
                                ToastManager.shared.info("جاري الانضمام لـ \(code)...")
                                onClose()
                            }
                        )
                        .id(msg.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.tappedMessageId = viewModel.tappedMessageId == msg.id ? nil : msg.id
                            }
                        }
                        .contextMenu {
                            messageContextMenu(msg)
                        } preview: {
                            // معاينة + شريط تفاعلات سريع
                            VStack(spacing: 8) {
                                ClanMessageBubble(message: msg, isMine: msg.user?.id == viewModel.myId)
                                    .padding(.top, 8)
                                ReactionQuickPicker { emoji in
                                    Task { await viewModel.react(to: msg, emoji: emoji) }
                                }
                                .padding(.bottom, 10)
                            }
                            .background(Color(hex: "0A0E27"))
                        }
                    }
                }
                .padding(.top, AppSizes.Spacing.sm)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.count) { old, new in
                if new > old, let last = viewModel.messages.first?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = viewModel.messages.first?.id {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func messageContextMenu(_ msg: ClanMessage) -> some View {
        if msg.type == .text || msg.type == .announcement {
            // تفاعلات سريعة
            Menu {
                ForEach(ReactionQuickPicker.quickReactions, id: \.self) { emoji in
                    Button(emoji) {
                        Task { await viewModel.react(to: msg, emoji: emoji) }
                    }
                }
            } label: {
                Label("تفاعل", systemImage: "face.smiling")
            }

            Button { viewModel.reply(to: msg) } label: {
                Label("رد", systemImage: "arrowshape.turn.up.left")
            }
            Button { viewModel.copy(msg) } label: {
                Label("نسخ", systemImage: "doc.on.doc")
            }
        }

        if viewModel.canManage {
            Button { Task { await viewModel.togglePin(msg) } } label: {
                Label(msg.isPinned == true ? "إلغاء التثبيت" : "تثبيت",
                      systemImage: msg.isPinned == true ? "pin.slash" : "pin")
            }
        }

        // حذف — صاحب الرسالة أو مشرف/زعيم
        let canDelete = (msg.user?.id == viewModel.myId) || viewModel.canManage
        if canDelete && msg.type != .system {
            Button(role: .destructive) {
                Task { await viewModel.deleteMessage(msg) }
            } label: {
                Label("حذف", systemImage: "trash")
            }
        }

        // كتم العضو (للمشرفين، ليس الرسائل الخاصة بي)
        if viewModel.canManage, let user = msg.user, user.id != viewModel.myId,
           let member = viewModel.members.first(where: { $0.id == user.id }),
           member.role != .owner {
            Button {
                muteTarget = member
            } label: {
                Label("كتم \(user.username)", systemImage: "mic.slash")
            }
        }

        // تبليغ (لأي رسالة مو تبعي)
        if msg.user?.id != viewModel.myId && msg.type != .system {
            Button {
                reportingMessage = msg
            } label: {
                Label("تبليغ", systemImage: "exclamationmark.triangle")
            }
        }
    }

    /// يظهر الفاصل إذا الرسالة في يوم جديد مقارنة باللي قبلها
    private func shouldShowDateSeparator(current: ClanMessage, previousIndex: Int, all: [ClanMessage]) -> Bool {
        guard let currentDate = current.date else { return false }
        guard previousIndex > 0 else { return true }  // أول رسالة دائماً
        guard let prev = all[previousIndex - 1].date else { return true }
        return !Calendar.current.isDate(currentDate, inSameDayAs: prev)
    }

    private var chatInputBar: some View {
        VStack(spacing: 0) {
            // Mention suggestions (فوق كل شي)
            if viewModel.mentionQuery != nil, !viewModel.mentionMatches.isEmpty {
                MentionSuggestionsList(members: viewModel.mentionMatches) { member in
                    viewModel.mention(member)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 4)
            }

            // مؤشّر "يكتب"
            if !viewModel.typingUsernames.isEmpty {
                HStack(spacing: 6) {
                    TypingDots()
                    Text(typingText)
                        .font(.cairo(.regular, size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.top, 4)
                .transition(.opacity)
            }

            // Reply preview
            if let target = viewModel.replyingTo {
                ChatReplyPreview(targetMessage: target) {
                    viewModel.cancelReply()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // الرسائل السريعة (Presets) — تظهر عند ما يكون مربع الكتابة فاضي
            if viewModel.messageText.isEmpty && !viewModel.showEmojiBar && viewModel.replyingTo == nil {
                ChatPresetsBar { preset in
                    Task { await viewModel.sendPreset(preset) }
                }
                .transition(.opacity)
            }

            // شريط الإيموجي
            if viewModel.showEmojiBar {
                ChatEmojiPickerBar { emoji in
                    viewModel.insertEmoji(emoji)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // صف الإدخال الرئيسي
            HStack(spacing: AppSizes.Spacing.xs) {
                // زر الإيموجي
                Button {
                    HapticManager.light()
                    withAnimation { viewModel.showEmojiBar.toggle() }
                } label: {
                    Image(systemName: viewModel.showEmojiBar ? "keyboard" : "face.smiling")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.showEmojiBar ? AppColors.Default.goldPrimary : .white.opacity(0.5))
                        .frame(width: 36, height: 36)
                }

                TextField("اكتب رسالة...", text: $viewModel.messageText, axis: .vertical)
                    .font(.cairo(.regular, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .tint(AppColors.Default.goldPrimary)
                    .lineLimit(1...4)
                    .padding(.horizontal, AppSizes.Spacing.sm)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onChange(of: viewModel.messageText) { _, new in
                        viewModel.onMessageTextChanged(new)
                    }

                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(viewModel.messageText.isEmpty ? .white.opacity(0.1) : AppColors.Default.goldPrimary)
                        .clipShape(Circle())
                }
                .disabled(viewModel.messageText.isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.vertical, AppSizes.Spacing.sm)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.typingUsernames.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showEmojiBar)
        .animation(.easeInOut(duration: 0.2), value: viewModel.replyingTo?.id)
        .animation(.easeInOut(duration: 0.2), value: viewModel.mentionQuery)
        .background(Color.black.opacity(0.2))
    }

    private var typingText: String {
        let names = Array(viewModel.typingUsernames)
        switch names.count {
        case 0: return ""
        case 1: return "\(names[0]) يكتب..."
        case 2: return "\(names[0]) و\(names[1]) يكتبان..."
        default: return "عدّة أعضاء يكتبون..."
        }
    }

    // MARK: - Members Tab (مجموعات حسب الدور)
    private var membersTab: some View {
        ScrollView {
            // عدّاد متصلين
            HStack {
                Label("\(viewModel.members.count) عضو", systemImage: "person.2.fill")
                    .font(.cairo(.semiBold, size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(AppColors.Default.success).frame(width: 6, height: 6)
                    Text("\(viewModel.onlineMembersCount) متصل")
                        .font(.cairo(.semiBold, size: 11))
                        .foregroundStyle(AppColors.Default.success)
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.top, AppSizes.Spacing.sm)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.membersByRole, id: \.role) { group in
                    // عنوان المجموعة
                    HStack(spacing: 6) {
                        Image(systemName: group.role.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(group.role.color)
                        Text("\(group.role.titleAr) (\(group.members.count))")
                            .font(.cairo(.bold, size: 11))
                            .foregroundStyle(group.role.color)
                        Spacer()
                    }
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.top, AppSizes.Spacing.md)
                    .padding(.bottom, 4)

                    ForEach(group.members) { member in
                        ClanMemberRow(
                            member: member,
                            canManage: viewModel.canManage && member.id != viewModel.myId,
                            onAction: { action in
                                if action == .mute {
                                    muteTarget = member
                                } else {
                                    Task { await viewModel.handleMember(member, action: action) }
                                }
                            }
                        )
                        Divider().overlay(.white.opacity(0.05)).padding(.leading, 60)
                    }
                }
            }
            .padding(.bottom, AppSizes.Spacing.lg)

            if viewModel.members.isEmpty { ClanEmptyState(icon: "person.2.slash", title: "لا أعضاء") }
        }
    }

    // MARK: - Stats Tab (إحصائيات + MVP)
    private var statsTab: some View {
        ScrollView {
            VStack(spacing: AppSizes.Spacing.md) {
                if let clan = viewModel.clan {
                    // Grid إحصائيات رئيسية
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                              spacing: 10) {
                        ClanStatTile(
                            icon: "chart.line.uptrend.xyaxis",
                            label: "نقاط الأسبوع",
                            value: "\(clan.weeklyPoints)",
                            color: clan.displayColor
                        )
                        ClanStatTile(
                            icon: "medal.fill",
                            label: "النقاط الكلية",
                            value: "\(clan.totalPoints ?? 0)",
                            color: Color(hex: "F59E0B")
                        )
                        ClanStatTile(
                            icon: "person.2.fill",
                            label: "الأعضاء",
                            value: "\(clan.memberCount ?? 0)/\(clan.maxMembers ?? 30)",
                            color: Color(hex: "22C55E")
                        )
                        ClanStatTile(
                            icon: "circle.fill",
                            label: "متصلون الآن",
                            value: "\(viewModel.onlineMembersCount)",
                            color: AppColors.Default.success
                        )
                    }

                    // تقدّم المستوى
                    VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 14))
                                .foregroundStyle(clan.displayColor)
                            Text("المستوى \(clan.level)")
                                .font(.cairo(.bold, size: AppSizes.Font.body))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(clan.levelProgress * 100))%")
                                .font(.poppins(.bold, size: 12))
                                .foregroundStyle(clan.displayColor)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.08))
                                Capsule()
                                    .fill(
                                        LinearGradient(colors: [clan.displayColor.opacity(0.6), clan.displayColor],
                                                       startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(width: geo.size.width * clan.levelProgress)
                                    .shadow(color: clan.displayColor.opacity(0.5), radius: 5)
                            }
                        }
                        .frame(height: 10)

                        Text(nextLevelHint(for: clan))
                            .font(.cairo(.regular, size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(AppSizes.Spacing.md)
                    .background(.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))

                    // MVP
                    if let mvp = viewModel.mvp, mvp.weeklyPoints > 0 {
                        mvpCard(mvp)
                    }

                    // الوصف
                    if let desc = clan.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("الوصف", systemImage: "text.alignright")
                                .font(.cairo(.semiBold, size: 11))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(desc)
                                .font(.cairo(.regular, size: AppSizes.Font.body))
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(AppSizes.Spacing.md)
                        .background(.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                    }

                    // إعدادات (للمالك فقط)
                    if viewModel.isOwner {
                        Button {
                            Task { await viewModel.toggleOpen() }
                        } label: {
                            HStack {
                                Image(systemName: (clan.isOpen ?? true) ? "lock" : "lock.open")
                                Text((clan.isOpen ?? true) ? "تحويل لمغلقة (بطلب)" : "تحويل لمفتوحة")
                                Spacer()
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10))
                            }
                            .font(.cairo(.semiBold, size: AppSizes.Font.body))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                            .padding(AppSizes.Spacing.md)
                            .background(AppColors.Default.goldPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                                    .stroke(AppColors.Default.goldPrimary.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
    }

    // MARK: - بطاقة MVP
    private func mvpCard(_ mvp: ClanMember) -> some View {
        HStack(spacing: AppSizes.Spacing.md) {
            ZStack(alignment: .topTrailing) {
                AvatarView(imageURL: mvp.avatarUrl, size: 56)
                Text("👑")
                    .font(.system(size: 18))
                    .offset(x: 4, y: -8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Label("نجم الأسبوع", systemImage: "star.fill")
                    .font(.cairo(.semiBold, size: 10))
                    .foregroundStyle(Color(hex: "FFD700"))
                Text(mvp.username)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                Text("\(mvp.weeklyPoints) نقطة هذا الأسبوع")
                    .font(.poppins(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(AppSizes.Spacing.md)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFD700").opacity(0.18), Color(hex: "FFD700").opacity(0.02)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(Color(hex: "FFD700").opacity(0.35), lineWidth: 1)
        )
    }

    private func nextLevelHint(for clan: Clan) -> String {
        let thresholds = [5_000, 15_000]
        if clan.level >= 3 { return "وصلت لأعلى مستوى حالياً" }
        let next = thresholds[min(clan.level - 1, thresholds.count - 1)]
        let remaining = max(0, next - clan.weeklyPoints)
        return "تحتاج \(remaining) نقطة للوصول للمستوى \(clan.level + 1)"
    }

    // MARK: - Leaderboard Tab
    private var leaderboardTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.leaderboard) { member in
                    ClanMemberRow(member: member)
                    Divider().overlay(.white.opacity(0.05)).padding(.leading, 60)
                }
            }
            .padding(.top, AppSizes.Spacing.sm)
            if viewModel.leaderboard.isEmpty { ClanEmptyState(icon: "chart.bar", title: "لا توجد بيانات") }
        }
    }

    // MARK: - Requests Tab (للمشرفين فقط)
    private var requestsTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.requests) { req in
                    HStack(spacing: AppSizes.Spacing.sm) {
                        AvatarView(imageURL: req.user.avatarUrl, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(req.user.username).font(.cairo(.bold, size: AppSizes.Font.body)).foregroundStyle(.white)
                            Text("المستوى \(req.user.level ?? 1)")
                                .font(.cairo(.regular, size: 10)).foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        Button { Task { await viewModel.accept(req) } } label: {
                            Text("قبول").font(.cairo(.semiBold, size: 11)).foregroundStyle(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(AppColors.Default.success).clipShape(Capsule())
                        }
                        Button { Task { await viewModel.reject(req) } } label: {
                            Text("رفض").font(.cairo(.semiBold, size: 11)).foregroundStyle(.red)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .overlay(Capsule().stroke(.red.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, AppSizes.Spacing.lg).padding(.vertical, AppSizes.Spacing.sm)
                    Divider().overlay(.white.opacity(0.05)).padding(.leading, 60)
                }
            }
            .padding(.top, AppSizes.Spacing.sm)
            if viewModel.requests.isEmpty { ClanEmptyState(icon: "tray", title: "لا توجد طلبات") }
        }
    }

}
