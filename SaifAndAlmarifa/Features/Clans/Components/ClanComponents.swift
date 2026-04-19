//
//  ClanComponents.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/Components/ClanComponents.swift
//  مكوّنات مشتركة لشاشات العشائر

import SwiftUI

// MARK: - شارة العشيرة (Badge + اللون)
struct ClanBadgeView: View {
    let badge: String?
    let color: Color
    var size: CGFloat = 56

    /// خريطة السلوك الافتراضي (badge name → SF Symbol / emoji)
    private var icon: String {
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

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.35), color.opacity(0.05)],
                        center: .center, startRadius: 2, endRadius: size / 1.5
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .strokeBorder(color.opacity(0.6), lineWidth: 2)
                .frame(width: size, height: size)

            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.6), radius: 8)
        }
    }
}

// MARK: - صف عشيرة (في البحث / الترتيب)
struct ClanRankRow: View {
    let entry: ClanRankEntry
    var onTap: () -> Void

    var body: some View {
        Button(action: { HapticManager.light(); onTap() }) {
            HStack(spacing: AppSizes.Spacing.sm) {
                // الترتيب
                rankBadge

                ClanBadgeView(badge: entry.badge, color: entry.displayColor, size: 44)

                // الاسم + الأعضاء
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.name)
                            .font(.cairo(.bold, size: AppSizes.Font.body))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        if entry.isOpen == false {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    HStack(spacing: 8) {
                        label(icon: "person.2.fill", text: "\(entry.memberCount)")
                        label(icon: "chart.line.uptrend.xyaxis", text: "\(entry.weeklyPoints)")
                        label(icon: "shield.lefthalf.filled", text: "Lv.\(entry.level)")
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.vertical, AppSizes.Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var rankBadge: some View {
        if let rank = entry.rank {
            let color: Color = {
                switch rank {
                case 1: return Color(hex: "FFD700")
                case 2: return Color(hex: "C0C0C0")
                case 3: return Color(hex: "CD7F32")
                default: return .white.opacity(0.35)
                }
            }()
            Text("\(rank)")
                .font(.poppins(.bold, size: 12))
                .foregroundStyle(rank <= 3 ? .black : .white)
                .frame(width: 28, height: 28)
                .background(color.opacity(rank <= 3 ? 1 : 0.12))
                .clipShape(Circle())
        } else {
            Color.clear.frame(width: 28, height: 28)
        }
    }

    private func label(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.poppins(.medium, size: 10))
        }
    }
}

// MARK: - صف عضو عشيرة
struct ClanMemberRow: View {
    let member: ClanMember
    var canManage: Bool = false
    var onTap: (() -> Void)? = nil
    var onAction: ((MemberAction) -> Void)? = nil

    enum MemberAction { case promote, demote, kick, transfer, mute, unmute }

    var body: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            // الترتيب (لو موجود)
            if let rank = member.rank {
                Text("\(rank)")
                    .font(.poppins(.bold, size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 24)
            }

            AvatarView(
                imageURL: member.avatarUrl,
                size: 40,
                showOnlineIndicator: member.isOnline != nil,
                isOnline: member.isOnline ?? false
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.username)
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Image(systemName: member.role.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(member.role.color)
                }
                HStack(spacing: 8) {
                    Text(member.role.titleAr)
                        .font(.cairo(.medium, size: 10))
                        .foregroundStyle(member.role.color)
                    Text("•").foregroundStyle(.white.opacity(0.2))
                    Text("\(member.weeklyPoints) نقطة")
                        .font(.poppins(.medium, size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            // مؤشر "مكتوم"
            if member.isMuted {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.Default.warning)
            }

            if canManage && member.role != .owner, let onAction {
                Menu {
                    if member.role == .member {
                        Button { onAction(.promote) } label: { Label("ترقية لمشرف", systemImage: "arrow.up.circle") }
                    }
                    if member.role == .admin {
                        Button { onAction(.demote) } label: { Label("تنزيل لعضو", systemImage: "arrow.down.circle") }
                    }
                    if member.isMuted {
                        Button { onAction(.unmute) } label: { Label("رفع الكتم", systemImage: "mic") }
                    } else {
                        Button { onAction(.mute) } label: { Label("كتم", systemImage: "mic.slash") }
                    }
                    Button { onAction(.transfer) } label: { Label("نقل الزعامة", systemImage: "crown") }
                    Button(role: .destructive) { onAction(.kick) } label: { Label("طرد", systemImage: "xmark.circle") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, AppSizes.Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

// MARK: - Empty state موحّد
struct ClanEmptyState: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.2))
            Text(title)
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.5))
            if let subtitle {
                Text(subtitle)
                    .font(.cairo(.regular, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSizes.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - شريط تابات أفقي
struct ClanTabBar: View {
    let tabs: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { idx, title in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) { selection = idx }
                } label: {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                            .foregroundStyle(selection == idx ? AppColors.Default.goldPrimary : .white.opacity(0.4))
                        Capsule()
                            .fill(selection == idx ? AppColors.Default.goldPrimary : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
    }
}

// MARK: - هيدر شاشة موحّد
struct ClanScreenHeader: View {
    let title: String
    var trailing: AnyView? = nil
    var onClose: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Text(title)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)
            HStack {
                if let onClose {
                    Button { onClose() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()
                if let trailing { trailing }
            }
        }
        .padding(AppSizes.Spacing.lg)
    }
}

// MARK: - فقاعة رسالة في الشات
struct ClanMessageBubble: View {
    let message: ClanMessage
    let isMine: Bool
    var showTimestamp: Bool = false   // إظهار الوقت (عند الضغط)
    var onReaction: ((String) -> Void)? = nil   // callback عند اختيار emoji
    var onJoinRoom: ((String) -> Void)? = nil   // callback عند اللمس على game_code

    var body: some View {
        Group {
            switch message.type {
            case .system:
                systemMessage
            case .game_code:
                gameCodeMessage
            case .text, .announcement:
                textMessage
            }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, 3)
    }

    // MARK: نص عادي
    private var textMessage: some View {
        HStack(alignment: .bottom, spacing: AppSizes.Spacing.xs) {
            if isMine { Spacer(minLength: 40) }
            if !isMine {
                AvatarView(imageURL: message.user?.avatarUrl, size: 28)
            }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                if !isMine, let user = message.user {
                    Text(user.username)
                        .font(.cairo(.semiBold, size: 10))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }

                // اقتباس الرد (إن وُجد)
                if let replyUser = message.replyToUsername, let snippet = message.replyToSnippet {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .font(.system(size: 8))
                            Text(replyUser)
                                .font(.cairo(.bold, size: 9))
                        }
                        .foregroundStyle(AppColors.Default.goldPrimary)
                        Text(snippet)
                            .font(.cairo(.regular, size: 10))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .frame(maxWidth: 220, alignment: .leading)
                    .background(AppColors.Default.goldPrimary.opacity(0.08))
                    .overlay(
                        HStack { Rectangle().fill(AppColors.Default.goldPrimary).frame(width: 2); Spacer() }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                HStack(spacing: 4) {
                    if message.type == .announcement {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "FFD700"))
                    }
                    Text(message.content.chatAttributed())
                        .font(.cairo(.regular, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, AppSizes.Spacing.sm)
                .padding(.vertical, 8)
                .background(
                    message.type == .announcement
                        ? Color(hex: "FFD700").opacity(0.12)
                        : (isMine ? Color(hex: "6366F1").opacity(0.25) : Color.white.opacity(0.06))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            message.type == .announcement
                                ? Color(hex: "FFD700").opacity(0.4)
                                : .white.opacity(0.08),
                            lineWidth: 1
                        )
                )

                // التفاعلات
                if let reactions = message.reactions, !reactions.isEmpty {
                    ReactionChipsView(reactions: reactions) { r in
                        onReaction?(r.emoji)
                    }
                }

                // الوقت
                if showTimestamp, let date = message.date {
                    Text(ChatDateFormat.timeLabel(for: date))
                        .font(.poppins(.medium, size: 9))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            if !isMine { Spacer(minLength: 40) }
        }
    }

    // MARK: كود لعبة
    private var gameCodeMessage: some View {
        HStack {
            if isMine { Spacer() }
            Button {
                guard !isMine, let code = message.roomCode else { return }
                HapticManager.medium()
                onJoinRoom?(code)
            } label: {
                VStack(alignment: .center, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundStyle(AppColors.Default.goldPrimary)
                        Text(message.content)
                            .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                            .foregroundStyle(.white)
                    }
                    if let code = message.roomCode {
                        Text(code)
                            .font(.poppins(.bold, size: 18))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                            .padding(.horizontal, AppSizes.Spacing.md)
                            .padding(.vertical, 6)
                            .background(AppColors.Default.goldPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    if !isMine {
                        Text("اضغط للانضمام →")
                            .font(.cairo(.semiBold, size: 10))
                            .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.8))
                    }
                }
                .padding(AppSizes.Spacing.sm)
                .background(Color(hex: "1E1B4B").opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            if !isMine { Spacer() }
        }
    }

    // MARK: رسالة نظام
    private var systemMessage: some View {
        HStack {
            Spacer()
            Text(message.content)
                .font(.cairo(.regular, size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, AppSizes.Spacing.sm)
                .padding(.vertical, 4)
                .background(.white.opacity(0.04))
                .clipShape(Capsule())
            Spacer()
        }
    }
}
