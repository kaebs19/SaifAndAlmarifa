//
//  LeaderboardModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation

struct LeaderboardPlayer: Decodable, Identifiable {
    let rank: Int
    let id: String
    let username: String
    let avatarUrl: String?
    let country: String?
    let level: Int?
    let totalPoints: Int?
    let weeklyPoints: Int?
    let wins: Int?

    var fullAvatarUrl: String? {
        guard let url = avatarUrl, !url.isEmpty else { return nil }
        if url.hasPrefix("http") { return url }
        return APIConfig.environment.baseURL.replacingOccurrences(of: "/api/v1", with: "") + url
    }
}

struct LeaderboardResponse: Decodable {
    let players: [LeaderboardPlayer]
    let myRank: Int?
}

enum LeaderboardType: String, CaseIterable {
    case allTime = "all_time"
    case weekly = "weekly"
    case friends = "friends"

    var title: String {
        switch self {
        case .allTime: return "الكل"
        case .weekly:  return "الأسبوع"
        case .friends: return "الأصدقاء"
        }
    }
}
