//
//  GameMode.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - أنماط اللعب
enum GameMode: String, CaseIterable, Identifiable {
    case random1v1
    case random4
    case private1v1
    case challengeFriend
    case friends4

    var id: String { rawValue }

    var title: String {
        switch self {
        case .random1v1:       return AppStrings.Main.random1v1
        case .random4:         return AppStrings.Main.random4
        case .private1v1:      return AppStrings.Main.private1v1
        case .challengeFriend: return AppStrings.Main.challengeFriend
        case .friends4:        return AppStrings.Main.friends4
        }
    }

    var subtitle: String {
        switch self {
        case .random1v1:       return AppStrings.Main.random1v1Sub
        case .random4:         return AppStrings.Main.random4Sub
        case .private1v1:      return AppStrings.Main.private1v1Sub
        case .challengeFriend: return AppStrings.Main.challengeFriendSub
        case .friends4:        return AppStrings.Main.friends4Sub
        }
    }

    var icon: String {
        switch self {
        case .random1v1:       return "icon_swords_crossed"
        case .random4:         return "icon_castle"
        case .private1v1:      return "icon_sword"
        case .challengeFriend: return "icon_shield"
        case .friends4:        return "icon_crown"
        }
    }

    var accentColor: Color {
        switch self {
        case .random1v1:       return AppColors.Default.goldPrimary
        case .random4:         return AppColors.Default.error
        case .private1v1:      return AppColors.Default.info
        case .challengeFriend: return AppColors.Default.success
        case .friends4:        return AppColors.Default.warning
        }
    }

    /// هل يستخدم طابور عشوائي أو غرفة خاصة
    var isQueue: Bool {
        self == .random1v1 || self == .random4
    }

    /// هل يحتاج اختيار صديق
    var needsFriend: Bool {
        self == .challengeFriend || self == .friends4
    }

    /// وضع المباراة للـ Socket
    var socketMode: String {
        switch self {
        case .random1v1, .private1v1, .challengeFriend: return "1v1"
        case .random4, .friends4: return "4player"
        }
    }

    // MARK: - تفاصيل اللوبي

    /// عدد اللاعبين المطلوبين
    var playersRequired: Int {
        switch self {
        case .random1v1, .private1v1, .challengeFriend: return 2
        case .random4, .friends4: return 4
        }
    }

    /// عدد الأسئلة في المباراة
    var questionsCount: Int { 10 }

    /// مدة المباراة التقديرية بالدقائق
    var estimatedMinutes: Int {
        switch self {
        case .random1v1, .private1v1, .challengeFriend: return 5
        case .random4, .friends4: return 8
        }
    }

    /// جائزة الفوز بالذهب
    var winReward: Int { 50 }

    /// جائزة الخسارة
    var loseReward: Int { 10 }

    /// هل يُشارك كود غرفة
    var hasRoomCode: Bool { !isQueue }

    /// مفاتيح الوصف (3 معلومات)
    struct Detail { let icon: String; let label: String; let value: String }

    var details: [Detail] {
        [
            Detail(icon: "person.2.fill", label: "لاعبين", value: "\(playersRequired)"),
            Detail(icon: "questionmark.circle.fill", label: "سؤال", value: "\(questionsCount)"),
            Detail(icon: "clock.fill", label: "دقائق", value: "~\(estimatedMinutes)")
        ]
    }
}

// MARK: - التابات الرئيسية
enum MainTab: String, CaseIterable {
    case home
    case leaderboard
    case shop
    case profile

    var title: String {
        switch self {
        case .home:        return AppStrings.Main.home
        case .leaderboard: return AppStrings.Main.leaderboard
        case .shop:        return AppStrings.Main.shop
        case .profile:     return AppStrings.Main.profile
        }
    }

    var icon: String {
        switch self {
        case .home:        return "house.fill"
        case .leaderboard: return "trophy.fill"
        case .shop:        return "bag.fill"
        case .profile:     return "person.fill"
        }
    }
}
