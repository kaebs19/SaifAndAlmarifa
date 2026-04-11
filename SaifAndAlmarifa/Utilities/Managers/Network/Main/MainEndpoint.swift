//
//  MainEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import Foundation

// MARK: - Main Endpoints
enum MainEndpoint {

    // MARK: المكافأة اليومية
    struct GetDailyRewardStatus: Endpoint {
        typealias Response = SaifAndAlmarifa.DailyRewardStatus
        var path: String { "/daily-reward/status" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct ClaimDailyReward: Endpoint {
        typealias Response = DailyRewardClaim
        var path: String { "/daily-reward/claim" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    // MARK: عجلة الحظ
    struct GetSpinStatus: Endpoint {
        typealias Response = SaifAndAlmarifa.SpinStatus
        var path: String { "/spin/status" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct Spin: Endpoint {
        typealias Response = SpinResult
        let useExtra: Bool
        var path: String { "/spin/spin" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? { ["useExtra": useExtra] }
    }

    // MARK: الإشعارات
    struct UnreadCount: Endpoint {
        typealias Response = NotificationCount
        var path: String { "/notifications/unread-count" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    // MARK: الأصدقاء
    struct FriendsList: Endpoint {
        typealias Response = [Friend]
        var path: String { "/friends" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    // MARK: الأفاتارات
    struct AvatarsList: Endpoint {
        typealias Response = [DefaultAvatarItem]
        var path: String { "/avatars" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }
}
