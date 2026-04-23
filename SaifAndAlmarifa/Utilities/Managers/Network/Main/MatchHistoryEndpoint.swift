//
//  MatchHistoryEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Main/MatchHistoryEndpoint.swift
//  تاريخ المباريات — GET /matches/history

import Foundation

enum MatchHistoryEndpoint {
    struct List: Endpoint {
        typealias Response = [MatchHistoryItem]
        let limit: Int
        init(limit: Int = 50) { self.limit = limit }
        var path: String { "/matches/history" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
        var queryItems: [URLQueryItem]? { [.init(name: "limit", value: "\(limit)")] }
    }
}

// MARK: - Model
struct MatchHistoryItem: Decodable, Identifiable {
    let id: String
    let mode: String               // "1v1" | "4player"
    let didIWin: Bool
    let myScore: Int
    let opponentName: String?
    let opponentAvatar: String?
    let opponentScore: Int
    let goldEarned: Int
    let xpEarned: Int
    let playedAt: String?

    var date: Date? {
        guard let s = playedAt else { return nil }
        return ISO8601DateFormatter().date(from: s)
    }
}
