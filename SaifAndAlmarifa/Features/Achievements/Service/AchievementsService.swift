//
//  AchievementsService.swift
//  SaifAndAlmarifa
//

import Foundation

@MainActor
final class AchievementsService: APIService {
    static let shared = AchievementsService()
    let network: NetworkClient = NetworkManager.shared
    private init() {}

    func getMine() async throws -> [Achievement] {
        try await network.request(AchievementsEndpoint.ListMine())
    }

    func getCatalog() async throws -> [Achievement] {
        try await network.request(AchievementsEndpoint.Catalog())
    }
}
