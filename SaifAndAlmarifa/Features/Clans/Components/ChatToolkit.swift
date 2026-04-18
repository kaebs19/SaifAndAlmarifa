//
//  ChatToolkit.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/Components/ChatToolkit.swift
//  مكوّنات الشات: presets، emoji picker، date separators، reply preview

import SwiftUI

// MARK: - رسائل سريعة (Presets)
enum ChatPreset: CaseIterable, Identifiable {
    case challenge, whoOnline, gameStart, wellDone, fire, hi, joinMe, gg

    var id: String { String(describing: self) }

    var text: String {
        switch self {
        case .challenge:   return "⚔️ من يقدر يتحدّاني؟"
        case .whoOnline:   return "👋 وين الشباب؟"
        case .gameStart:   return "🎮 لعبة جديدة! من معي؟"
        case .wellDone:    return "👏 أحسنت!"
        case .fire:        return "🔥 نار!"
        case .hi:           return "السلام عليكم 🌙"
        case .joinMe:       return "🎯 تعال العب معي"
        case .gg:          return "🏆 GG! لعبة ممتازة"
        }
    }

    var short: String {
        switch self {
        case .challenge: return "تحدّي ⚔️"
        case .whoOnline: return "وين الشباب 👋"
        case .gameStart: return "لعبة 🎮"
        case .wellDone:  return "أحسنت 👏"
        case .fire:      return "نار 🔥"
        case .hi:        return "سلام 🌙"
        case .joinMe:    return "تعال 🎯"
        case .gg:        return "GG 🏆"
        }
    }
}

struct ChatPresetsBar: View {
    var onPick: (ChatPreset) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSizes.Spacing.xs) {
                ForEach(ChatPreset.allCases) { preset in
                    Button {
                        HapticManager.light()
                        onPick(preset)
                    } label: {
                        Text(preset.short)
                            .font(.cairo(.semiBold, size: 11))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, AppSizes.Spacing.sm)
                            .padding(.vertical, 6)
                            .background(AppColors.Default.goldPrimary.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Emoji Picker خفيف (شريط)
struct ChatEmojiPickerBar: View {
    static let quickEmojis: [String] = [
        "😂", "❤️", "🔥", "👏", "🎉", "😮", "😢", "🥺",
        "👑", "⚔️", "🛡️", "💎", "🪙", "🏆", "🎮", "🌙",
        "🤝", "💪", "😎", "🤔", "🙏", "👋", "👍", "👎"
    ]

    var onPick: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Self.quickEmojis, id: \.self) { e in
                    Button {
                        HapticManager.selection()
                        onPick(e)
                    } label: {
                        Text(e)
                            .font(.system(size: 24))
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.25))
    }
}

// MARK: - فاصل التاريخ
struct ChatDateSeparator: View {
    let label: String

    var body: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
            Text(label)
                .font(.cairo(.medium, size: 10))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, AppSizes.Spacing.sm)
                .padding(.vertical, 3)
                .background(.white.opacity(0.05))
                .clipShape(Capsule())
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, 6)
    }
}

// MARK: - فورمات التاريخ/الوقت
enum ChatDateFormat {
    static func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "اليوم" }
        if cal.isDateInYesterday(date) { return "أمس" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar")
        f.dateFormat = "EEEE، d MMMM"
        return f.string(from: date)
    }

    static func timeLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar")
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

// MARK: - Reply Preview (فوق مربع الكتابة)
struct ChatReplyPreview: View {
    let targetMessage: ClanMessage
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Rectangle()
                .fill(AppColors.Default.goldPrimary)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                    Text(targetMessage.user?.username ?? "رسالة")
                        .font(.cairo(.bold, size: 11))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
                Text(targetMessage.content)
                    .font(.cairo(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, AppSizes.Spacing.md)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Mention Suggestions (قائمة الاقتراحات عند @)
struct MentionSuggestionsList: View {
    let members: [ClanMember]
    var onPick: (ClanMember) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(members.prefix(5)) { member in
                Button {
                    HapticManager.selection()
                    onPick(member)
                } label: {
                    HStack(spacing: AppSizes.Spacing.sm) {
                        AvatarView(imageURL: member.avatarUrl, size: 28)
                        Text("@\(member.username)")
                            .font(.cairo(.semiBold, size: AppSizes.Font.body))
                            .foregroundStyle(.white)
                        Image(systemName: member.role.icon)
                            .font(.system(size: 9))
                            .foregroundStyle(member.role.color)
                        Spacer()
                    }
                    .padding(.horizontal, AppSizes.Spacing.md)
                    .padding(.vertical, 8)
                }
                if member.id != members.prefix(5).last?.id {
                    Divider().overlay(.white.opacity(0.05))
                }
            }
        }
        .background(Color(hex: "1A1147").opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.Default.goldPrimary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        .padding(.horizontal, AppSizes.Spacing.lg)
    }
}

// MARK: - شريط تفاعلات سريعة (يظهر عند Long press)
struct ReactionQuickPicker: View {
    static let quickReactions: [String] = ["❤️", "🔥", "👏", "😂", "😮", "😢"]

    var onPick: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Self.quickReactions, id: \.self) { emoji in
                Button {
                    HapticManager.selection()
                    onPick(emoji)
                } label: {
                    Text(emoji)
                        .font(.system(size: 22))
                        .padding(6)
                        .background(.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: "1A1147").opacity(0.95))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }
}

// MARK: - عرض التفاعلات تحت الرسالة (شرائط)
struct ReactionChipsView: View {
    let reactions: [MessageReaction]
    var onTap: (MessageReaction) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(reactions) { r in
                Button {
                    HapticManager.selection()
                    onTap(r)
                } label: {
                    HStack(spacing: 3) {
                        Text(r.emoji).font(.system(size: 12))
                        Text("\(r.count)")
                            .font(.poppins(.bold, size: 10))
                            .foregroundStyle(r.mine ? AppColors.Default.goldPrimary : .white.opacity(0.7))
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(r.mine ? AppColors.Default.goldPrimary.opacity(0.15) : .white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(r.mine ? AppColors.Default.goldPrimary.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - AttributedString helper للرسائل مع @mentions
extension String {
    /// يرجّع AttributedString مع تمييز @mentions بلون ذهبي
    func chatAttributed(highlightColor: Color = Color(hex: "FFD700")) -> AttributedString {
        var attr = AttributedString(self)
        let pattern = "@[\\p{L}0-9_]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return attr }
        let range = NSRange(self.startIndex..., in: self)
        regex.enumerateMatches(in: self, range: range) { match, _, _ in
            guard let match, let range = Range(match.range, in: self) else { return }
            let low = AttributedString.Index(range.lowerBound, within: attr)
            let up  = AttributedString.Index(range.upperBound, within: attr)
            if let low, let up {
                attr[low..<up].foregroundColor = highlightColor
                attr[low..<up].font = .system(size: 14, weight: .semibold)
            }
        }
        return attr
    }
}
