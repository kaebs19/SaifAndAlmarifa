//
//  MainModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import Foundation

// MARK: - المكافأة اليومية
struct DailyRewardStatus: Decodable {
    let claimed: Bool
    let streak: Int
    let currentDay: Int
    let todayReward: DailyRewardItem?
    let rewards: [DailyRewardItem]?
}

struct DailyRewardItem: Decodable {
    let type: String
    let value: String?
    let label: String
}

struct DailyRewardClaim: Decodable {
    let reward: DailyRewardItem
    let streak: Int
    let currentDay: Int
}

// MARK: - عجلة الحظ
struct SpinStatus: Decodable {
    let canSpin: Bool
    let nextFreeInSeconds: Int?
    let extraSpinsUsed: Int?
    let maxExtraSpins: Int?
    let extraSpinCost: Int?
    let slots: [SpinSlot]?
}

struct SpinSlot: Decodable {
    let label: String
    let type: String
    let value: Int?
}

struct SpinResult: Decodable {
    let slotIndex: Int
    let reward: SpinSlot
}

// MARK: - الإشعارات
struct NotificationCount: Decodable {
    let count: Int
}

// MARK: - الأصدقاء
struct Friend: Decodable, Identifiable {
    let friendshipId: String?
    let id: String
    let username: String
    let avatarUrl: String?
    let level: Int?
    let country: String?
    let friendCode: String?
    let isOnline: Bool?
}

// MARK: - الأفاتارات الافتراضية
struct DefaultAvatarItem: Decodable, Identifiable {
    let id: String
    let name: String
    let imageUrl: String
    let gemCost: Int?
    let sortOrder: Int?
}
