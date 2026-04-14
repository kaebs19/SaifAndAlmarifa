//
//  LeaderboardEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation

enum LeaderboardEndpoint {
    struct Get: Endpoint {
        typealias Response = LeaderboardResponse
        let type: LeaderboardType
        var path: String { "/leaderboard" }
        var method: HTTPMethod { .get }
        var queryItems: [URLQueryItem]? { [.init(name: "type", value: type.rawValue)] }
        var requiresAuth: Bool { true }
    }
}
