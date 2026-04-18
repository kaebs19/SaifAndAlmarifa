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
}

// MARK: - رسالة داخل الشات
struct ClanMessage: Decodable, Identifiable {
    let id: String
    let type: MessageType
    let content: String
    let isPinned: Bool?
    let roomCode: String?
    let user: MessageUser?
    let createdAt: String?

    enum MessageType: String, Decodable {
        case text, game_code, system, announcement
    }

    struct MessageUser: Decodable {
        let id: String
        let username: String
        let avatarUrl: String?
    }

    // أسماء مفاتيح JSON (السيرفر يرسل "User")
    enum CodingKeys: String, CodingKey {
        case id, type, content, isPinned, roomCode, createdAt
        case user = "User"
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

// MARK: - صفحة شات (Pagination Envelope)
struct ChatPage: Decodable {
    let messages: [ClanMessage]
    let hasMore: Bool
    let nextBefore: String?
    let limit: Int?
}
