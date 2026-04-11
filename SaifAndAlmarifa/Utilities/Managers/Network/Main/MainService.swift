//
//  MainService.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import Foundation

// MARK: - خدمة الشاشة الرئيسية
@MainActor
final class MainService: APIService {
    static let shared = MainService()
    let network: NetworkClient = NetworkManager.shared
    private init() {}

    // MARK: عدد الإشعارات
    func getUnreadCount() async throws -> Int {
        let result = try await network.request(MainEndpoint.UnreadCount())
        return result.count
    }

    // MARK: المكافأة اليومية
    func getDailyRewardStatus() async throws -> DailyRewardStatus {
        try await network.request(MainEndpoint.GetDailyRewardStatus())
    }

    func claimDailyReward() async throws -> DailyRewardClaim {
        try await network.request(MainEndpoint.ClaimDailyReward())
    }

    // MARK: عجلة الحظ
    func getSpinStatus() async throws -> SpinStatus {
        try await network.request(MainEndpoint.GetSpinStatus())
    }

    func spin(useExtra: Bool = false) async throws -> SpinResult {
        try await network.request(MainEndpoint.Spin(useExtra: useExtra))
    }

    // MARK: الأصدقاء
    func getFriends() async throws -> [Friend] {
        try await network.request(MainEndpoint.FriendsList())
    }

    // MARK: الأفاتارات
    func getAvatars() async throws -> [DefaultAvatarItem] {
        try await network.request(MainEndpoint.AvatarsList())
    }
}
