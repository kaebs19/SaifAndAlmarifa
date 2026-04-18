//
//  ClanModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Clans/ClanModels.swift
//  نماذج بيانات نظام العشائر

import Foundation
import SwiftUI

// MARK: - الدور داخل العشيرة
enum ClanRole: String, Codable {
    case owner, admin, member

    var titleAr: String {
        switch self {
        case .owner:  return "زعيم"
        case .admin:  return "مشرف"
        case .member: return "عضو"
        }
    }

    var icon: String {
        switch self {
        case .owner:  return "crown.fill"
        case .admin:  return "star.fill"
        case .member: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .owner:  return Color(hex: "FFD700")
        case .admin:  return Color(hex: "60A5FA")
        case .member: return .white.opacity(0.5)
        }
    }

    var canManage: Bool { self == .owner || self == .admin }
}

// MARK: - العشيرة
struct Clan: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let badge: String?
    let color: String?
    let level: Int
    let weeklyPoints: Int
    let totalPoints: Int?
    let memberCount: Int?
    let maxMembers: Int?
    let isOpen: Bool?
    let readOnly: Bool?         // وضع الإعلانات فقط (admins only can send)
    let treasury: Int?          // خزينة الذهب المشترك
    let ownerId: String?
    let createdAt: String?

    // Returned from /clans/my
    let myRole: ClanRole?

    var displayColor: Color {
        guard let hex = color, !hex.isEmpty else { return Color(hex: "FFD700") }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }

    var levelProgress: Double {
        let thresholds = [0, 5_000, 15_000]
        let current = weeklyPoints
        let currentLvl = min(level, thresholds.count)
        let lower = thresholds[max(0, currentLvl - 1)]
        let upper = currentLvl < thresholds.count ? thresholds[currentLvl] : lower + 10_000
        let range = max(1, upper - lower)
        return min(1.0, Double(max(0, current - lower)) / Double(range))
    }
}

// MARK: - بطاقة عشيرة في الترتيب / البحث
struct ClanRankEntry: Codable, Identifiable {
    let rank: Int?
    let id: String
    let name: String
    let badge: String?
    let color: String?
    let level: Int
    let weeklyPoints: Int
    let memberCount: Int
    let isOpen: Bool?

    var displayColor: Color {
        guard let hex = color, !hex.isEmpty else { return Color(hex: "FFD700") }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }
}

// MARK: - عضو العشيرة
struct ClanMember: Decodable, Identifiable {
    let id: String
    let username: String
    let avatarUrl: String?
    let role: ClanRole
    let level: Int?
    let weeklyPoints: Int
    let isOnline: Bool?
    let rank: Int?
    /// حتى متى مكتوم (ISO string). nil = غير مكتوم
    let mutedUntil: String?

    var isMuted: Bool {
        guard let s = mutedUntil,
              let date = ISO8601DateFormatter().date(from: s) else { return false }
        return date > Date()
    }
}

// MARK: - تفاعل على رسالة
struct MessageReaction: Codable, Identifiable, Hashable {
    let emoji: String
    let count: Int
    let mine: Bool
    var id: String { emoji }
}

// MARK: - رسالة داخل الشات
struct ClanMessage: Codable, Identifiable {
    let id: String
    let type: MessageType
    let content: String
    let isPinned: Bool?
    let roomCode: String?
    let user: MessageUser?
    let createdAt: String?
    /// للرد/الاقتباس — id الرسالة الأصلية + مقتطف (اختياري)
    let replyToId: String?
    let replyToSnippet: String?
    let replyToUsername: String?
    /// تفاعلات
    var reactions: [MessageReaction]?

    enum MessageType: String, Codable {
        case text, game_code, system, announcement
    }

    struct MessageUser: Codable {
        let id: String
        let username: String
        let avatarUrl: String?
    }

    // أسماء مفاتيح JSON (السيرفر يرسل "User")
    enum CodingKeys: String, CodingKey {
        case id, type, content, isPinned, roomCode, createdAt
        case user = "User"
        case replyToId, replyToSnippet, replyToUsername
        case reactions
    }

    // MARK: - Helpers
    /// وقت الرسالة كـ Date
    var date: Date? {
        guard let createdAt else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: createdAt) ?? ISO8601DateFormatter().date(from: createdAt)
    }

    /// استخراج @mentions من النص
    var mentions: [String] {
        let pattern = "@([\\p{L}0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(content.startIndex..., in: content)
        return regex.matches(in: content, range: range).compactMap {
            Range($0.range(at: 1), in: content).map { String(content[$0]) }
        }
    }
}

// MARK: - طلب انضمام
struct ClanJoinRequest: Decodable, Identifiable {
    let id: String
    let user: RequestUser
    let requestedAt: String?

    struct RequestUser: Decodable {
        let id: String
        let username: String
        let avatarUrl: String?
        let level: Int?
    }
}

// MARK: - ردود العمليات
struct ClanJoinResponse: Decodable {
    /// "joined" | "pending"
    let status: String
    var isJoined: Bool { status == "joined" }
}

// MARK: - Treasury
struct TreasuryDonationResult: Decodable {
    let amount: Int
    let newTreasury: Int
    let newUserGold: Int
}

struct TreasuryTransaction: Decodable, Identifiable {
    let id: String
    let type: String             // "donation" | "withdraw"
    let amount: Int
    let user: TreasuryUser?
    let createdAt: String?
    let note: String?

    struct TreasuryUser: Decodable {
        let id: String
        let username: String
        let avatarUrl: String?
    }
}

// MARK: - Clan Wars
struct ClanWar: Decodable, Identifiable {
    let id: String
    let status: WarStatus
    let startAt: String?
    let endAt: String?
    let myClan: WarSide
    let enemyClan: WarSide
    let winnerClanId: String?

    enum WarStatus: String, Decodable {
        case scheduled, active, ended
    }

    struct WarSide: Decodable {
        let clanId: String
        let name: String
        let badge: String?
        let color: String?
        let score: Int
    }

    var isActive: Bool { status == .active }
    var isEnded: Bool { status == .ended }
    var didWin: Bool { winnerClanId == myClan.clanId }

    var displayColorEnemy: Color {
        guard let hex = enemyClan.color, !hex.isEmpty else { return .red }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }

    var displayColorMine: Color {
        guard let hex = myClan.color, !hex.isEmpty else { return Color(hex: "FFD700") }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }
}

// MARK: - حدث في سجل العشيرة
struct ClanEvent: Decodable, Identifiable {
    let id: String
    let type: EventType
    let createdAt: String?
    let actor: EventUser?      // من قام بالفعل
    let target: EventUser?     // المتأثر (إن وُجد)
    let metadata: [String: String]?

    enum EventType: String, Decodable {
        case memberJoined      = "member_joined"
        case memberLeft        = "member_left"
        case memberKicked      = "member_kicked"
        case memberPromoted    = "member_promoted"
        case memberDemoted     = "member_demoted"
        case memberMuted       = "member_muted"
        case memberUnmuted     = "member_unmuted"
        case clanCreated       = "clan_created"
        case clanUpdated       = "clan_updated"
        case ownerTransferred  = "owner_transferred"
        case levelUp           = "level_up"
        case warWon            = "war_won"
        case warLost           = "war_lost"
        case treasuryDonation  = "treasury_donation"
        case unknown
    }

    struct EventUser: Decodable {
        let id: String
        let username: String
        let avatarUrl: String?
    }

    /// وصف الحدث بالعربي
    var arabicDescription: String {
        let actorName = actor?.username ?? "شخص"
        let targetName = target?.username ?? "عضو"
        switch type {
        case .memberJoined:      return "\(actorName) انضم للعشيرة 🎉"
        case .memberLeft:        return "\(actorName) غادر العشيرة"
        case .memberKicked:      return "\(actorName) طرد \(targetName)"
        case .memberPromoted:    return "\(actorName) ترقّى لمشرف ⭐"
        case .memberDemoted:     return "\(targetName) تم تنزيله لعضو"
        case .memberMuted:       return "\(actorName) كتم \(targetName) 🔇"
        case .memberUnmuted:     return "\(actorName) رفع الكتم عن \(targetName)"
        case .clanCreated:       return "تأسست العشيرة 🎊"
        case .clanUpdated:       return "\(actorName) حدّث معلومات العشيرة"
        case .ownerTransferred:  return "\(actorName) سلّم الزعامة لـ \(targetName) 👑"
        case .levelUp:
            let lvl = metadata?["level"] ?? "?"
            return "العشيرة وصلت للمستوى \(lvl) 🚀"
        case .warWon:            return "فزنا في الحرب! 🏆"
        case .warLost:           return "خسرنا الحرب 💔"
        case .treasuryDonation:
            let amount = metadata?["amount"] ?? "0"
            return "\(actorName) تبرّع بـ \(amount) 🪙"
        case .unknown:           return "حدث"
        }
    }

    var icon: String {
        switch type {
        case .memberJoined, .memberLeft: return "person.crop.circle"
        case .memberKicked, .memberMuted: return "xmark.circle.fill"
        case .memberPromoted: return "arrow.up.circle.fill"
        case .memberDemoted:  return "arrow.down.circle.fill"
        case .memberUnmuted:  return "mic.fill"
        case .clanCreated:    return "sparkles"
        case .clanUpdated:    return "pencil.circle"
        case .ownerTransferred: return "crown.fill"
        case .levelUp:        return "arrow.up.square.fill"
        case .warWon:         return "trophy.fill"
        case .warLost:        return "flag.slash"
        case .treasuryDonation: return "dollarsign.circle.fill"
        case .unknown:        return "circle"
        }
    }

    var date: Date? {
        guard let s = createdAt else { return nil }
        return ISO8601DateFormatter().date(from: s)
    }
}

// MARK: - صفحة شات (Pagination Envelope)
struct ChatPage: Decodable {
    let messages: [ClanMessage]
    let hasMore: Bool
    let nextBefore: String?
    let limit: Int?
}
