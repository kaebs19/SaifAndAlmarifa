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
    @Environment(\.dismiss) private var dismiss

    @State private var showLeaveConfirm = false
    @State private var showDeleteConfirm = false
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
                    membersTab.tag(1)
                    leaderboardTab.tag(2)
                    if viewModel.canManage { requestsTab.tag(3); infoTab.tag(4) }
                    else { infoTab.tag(3) }
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
                            ForEach(viewModel.messages.reversed()) { msg in
                                ClanMessageBubble(
                                    message: msg,
                                    isMine: msg.user?.id == viewModel.myId
                                )
                                .id(msg.id)
                                .contextMenu {
                                    if viewModel.canManage {
                                        Button { Task { await viewModel.togglePin(msg) } } label: {
                                            Label(msg.isPinned == true ? "إلغاء التثبيت" : "تثبيت",
                                                  systemImage: msg.isPinned == true ? "pin.slash" : "pin")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, AppSizes.Spacing.sm)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: viewModel.messages.count) { old, new in
                        // scroll للأسفل فقط لو رسالة جديدة (وليس عند load more قديم)
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

            if viewModel.isMember {
                chatInputBar
            }
        }
    }

    private var chatInputBar: some View {
        VStack(spacing: 4) {
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
                .transition(.opacity)
            }

            HStack(spacing: AppSizes.Spacing.sm) {
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
                        if !new.isEmpty { viewModel.notifyTyping() }
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

    // MARK: - Members Tab
    private var membersTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.members) { member in
                    ClanMemberRow(
                        member: member,
                        canManage: viewModel.canManage && member.id != viewModel.myId,
                        onAction: { action in
                            Task { await viewModel.handleMember(member, action: action) }
                        }
                    )
                    Divider().overlay(.white.opacity(0.05)).padding(.leading, 60)
                }
            }
            .padding(.top, AppSizes.Spacing.sm)
            if viewModel.members.isEmpty { ClanEmptyState(icon: "person.2.slash", title: "لا أعضاء") }
        }
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

    // MARK: - Info Tab
    private var infoTab: some View {
        ScrollView {
            VStack(spacing: AppSizes.Spacing.md) {
                if let clan = viewModel.clan {
                    infoCard(title: "الوصف", value: clan.description ?? "لا يوجد", icon: "text.alignright")
                    infoCard(title: "نقاط هذا الأسبوع", value: "\(clan.weeklyPoints)", icon: "chart.line.uptrend.xyaxis")
                    if let total = clan.totalPoints {
                        infoCard(title: "النقاط الكلية", value: "\(total)", icon: "medal.fill")
                    }
                    infoCard(title: "الأعضاء", value: "\(clan.memberCount ?? 0) / \(clan.maxMembers ?? 30)", icon: "person.2.fill")
                    infoCard(title: "الحالة", value: (clan.isOpen ?? true) ? "مفتوحة" : "بطلب انضمام", icon: (clan.isOpen ?? true) ? "lock.open" : "lock")

                    if viewModel.isOwner {
                        Button {
                            Task { await viewModel.toggleOpen() }
                        } label: {
                            HStack {
                                Image(systemName: (clan.isOpen ?? true) ? "lock" : "lock.open")
                                Text((clan.isOpen ?? true) ? "تحويل لمغلقة (بطلب)" : "تحويل لمفتوحة")
                            }
                            .font(.cairo(.semiBold, size: AppSizes.Font.body))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSizes.Spacing.md)
                            .background(AppColors.Default.goldPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                        }
                    }
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
    }

    private func infoCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.Default.goldPrimary)
                .frame(width: 32, height: 32)
                .background(AppColors.Default.goldPrimary.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.cairo(.regular, size: 11)).foregroundStyle(.white.opacity(0.5))
                Text(value).font(.cairo(.semiBold, size: AppSizes.Font.body)).foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(AppSizes.Spacing.md)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
    }
}
