//
//  Achievement.swift
//  SaifAndAlmarifa
//
//  Models for the achievements feature
//

import Foundation

// MARK: - Achievement (catalog item with optional unlock state)

struct Achievement: Decodable, Identifiable, Equatable {
    let key: String
    let titleAr: String
    let descAr: String
    let icon: String          // SF Symbol name
    let color: String         // hex (e.g. "#FFD700")
    let rewardGold: Int
    let rewardXp: Int
    let isUnlocked: Bool?     // nil for catalog-only response
    let unlockedAt: Date?

    var id: String { key }
}

// MARK: - Unlock event payload (socket: achievement:unlocked)

struct AchievementUnlock: Decodable, Identifiable, Equatable {
    let key: String
    let titleAr: String
    let descAr: String
    let icon: String
    let color: String
    let rewardGold: Int
    let rewardXp: Int
    let unlockedAt: Date?

    var id: String { key }

    static func from(_ dict: [String: Any]) -> AchievementUnlock? {
        guard let key = dict["key"] as? String,
              let titleAr = dict["titleAr"] as? String,
              let descAr = dict["descAr"] as? String,
              let icon = dict["icon"] as? String,
              let color = dict["color"] as? String else { return nil }

        let unlockedAtStr = dict["unlockedAt"] as? String
        let date: Date? = {
            guard let s = unlockedAtStr else { return nil }
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
        }()

        return AchievementUnlock(
            key: key,
            titleAr: titleAr,
            descAr: descAr,
            icon: icon,
            color: color,
            rewardGold: (dict["rewardGold"] as? Int) ?? 0,
            rewardXp: (dict["rewardXp"] as? Int) ?? 0,
            unlockedAt: date
        )
    }
}
