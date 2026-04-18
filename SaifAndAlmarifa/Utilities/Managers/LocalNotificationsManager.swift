//
//  LocalNotificationsManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/LocalNotificationsManager.swift
//  جدولة إشعارات محلية (لا تحتاج السيرفر) لتذكير المستخدم
//  بالمكافآت المتاحة: عجلة الحظ + المكافأة اليومية + كتم منتهي + إلخ

import Foundation
import UserNotifications

@MainActor
enum LocalNotificationsManager {

    // MARK: - Identifiers (للإلغاء بدقة)
    enum NotificationID: String {
        case dailyReward = "local.daily_reward.ready"
        case spinWheel   = "local.spin_wheel.ready"
        case muteEnded   = "local.mute.ended"
    }

    // MARK: - Public

    /// جدولة تذكير المكافأة اليومية
    static func scheduleDailyReward(after seconds: TimeInterval) {
        guard seconds > 0 else { return }
        schedule(
            id: .dailyReward,
            title: "🎁 مكافأتك اليومية جاهزة!",
            body: "ادخل للتطبيق واحصل على مكافأتك اليومية",
            after: seconds,
            data: ["type": NotificationType.dailyReward.rawValue]
        )
    }

    /// جدولة تذكير عجلة الحظ
    static func scheduleSpinWheel(after seconds: TimeInterval) {
        guard seconds > 0 else { return }
        schedule(
            id: .spinWheel,
            title: "🎡 عجلة الحظ جاهزة!",
            body: "دوّرها الآن واحصل على جائزة",
            after: seconds,
            data: ["type": NotificationType.spinWheel.rawValue]
        )
    }

    /// جدولة تذكير انتهاء الكتم
    static func scheduleMuteEnded(after seconds: TimeInterval, clanId: String) {
        guard seconds > 0 else { return }
        schedule(
            id: .muteEnded,
            title: "🎤 انتهى الكتم",
            body: "تقدر ترسل رسائل في العشيرة الآن",
            after: seconds,
            data: [
                "type": NotificationType.muteEnded.rawValue,
                "clanId": clanId
            ]
        )
    }

    /// إلغاء إشعار محدّد
    static func cancel(_ id: NotificationID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id.rawValue])
    }

    /// إلغاء كل الإشعارات المحلية (عند logout)
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Notification Types
    enum NotificationType: String {
        case dailyReward = "daily_reward_ready"
        case spinWheel   = "spin_wheel_ready"
        case muteEnded   = "mute_ended"
    }

    // MARK: - Private
    private static func schedule(
        id: NotificationID,
        title: String,
        body: String,
        after seconds: TimeInterval,
        data: [String: Any]
    ) {
        // إلغاء السابق أولاً
        cancel(id)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.userInfo = data

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: id.rawValue, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("⚠️ [Local] Schedule failed: \(error)")
            } else {
                let hours = Int(seconds) / 3600
                let mins  = (Int(seconds) % 3600) / 60
                print("✅ [Local] \(id.rawValue) scheduled in \(hours)h\(mins)m")
            }
            #endif
        }
    }
}
