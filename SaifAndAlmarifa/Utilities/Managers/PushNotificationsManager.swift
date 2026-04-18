//
//  PushNotificationsManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/PushNotificationsManager.swift
//  إدارة إشعارات APNs — الصلاحية، التسجيل، التعامل مع الاستلام

import Foundation
import UIKit
import UserNotifications
import Combine
import FirebaseMessaging

@MainActor
final class PushNotificationsManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = PushNotificationsManager()

    // MARK: - State
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    /// FCM token (Firebase Cloud Messaging) — هذا اللي يُرسل للسيرفر
    @Published private(set) var fcmToken: String?

    /// يُبث عند لمس إشعار (يمكن للـ UI الانتقال للشاشة المناسبة)
    let onNotificationTap = PassthroughSubject<NotificationPayload, Never>()

    // MARK: - Dependencies
    private let center = UNUserNotificationCenter.current()
    private let keychain = KeychainManager.shared
    private let network: NetworkClient = NetworkManager.shared

    // MARK: - Init
    override init() {
        super.init()
        center.delegate = self
        Task { await refreshStatus() }
    }

    // MARK: - Public

    /// طلب صلاحية الإشعارات + تسجيل للـ remote notifications
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshStatus()
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
            return granted
        } catch {
            return false
        }
    }

    /// حدّث الحالة من النظام
    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// يُستدعى من AppDelegate عند فشل تسجيل APNs
    func didFailToRegister(error: Error) {
        #if DEBUG
        print("⚠️ [Push] APNs register failed: \(error)")
        #endif
    }

    /// إلغاء تسجيل عند logout
    func unregister() async {
        // حذف FCM token محلياً
        try? await Messaging.messaging().deleteToken()
        fcmToken = nil
        keychain.delete(.deviceToken)
        _ = try? await network.requestVoid(DeviceEndpoint.Unregister())
    }

    /// مسح badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Private

    private func sendTokenToServer(_ token: String) async {
        do {
            _ = try await network.requestVoid(
                DeviceEndpoint.Register(deviceToken: token, platform: "ios")
            )
            #if DEBUG
            print("✅ [FCM] Token registered with server")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [FCM] Token register failed: \(error)")
            #endif
        }
    }
}

// MARK: - Firebase Messaging Delegate (FCM token lifecycle)
extension PushNotificationsManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { @MainActor in
            self.fcmToken = token
            self.keychain.save(token, for: .deviceToken)
            #if DEBUG
            print("✅ [FCM] New token: \(String(token.prefix(20)))...")
            #endif
            await self.sendTokenToServer(token)
        }
    }
}

// MARK: - Delegate (Foreground + Tap)
extension PushNotificationsManager: UNUserNotificationCenterDelegate {

    // عند وصول إشعار والتطبيق مفتوح
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    // عند لمس الإشعار
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let payload = NotificationPayload.from(userInfo)
        Task { @MainActor in
            self.onNotificationTap.send(payload)
        }
        completionHandler()
    }
}

// MARK: - حمل الإشعار (parsing)
struct NotificationPayload {
    /// نوع الإشعار — يطابق `data.type` من FCM
    let type: NotificationType
    let clanId: String?
    let messageId: String?
    let userId: String?
    let raw: [AnyHashable: Any]

    enum NotificationType: String {
        case clanMessage           = "clan_message"
        case clanMention           = "clan_mention"
        case clanMemberJoined      = "clan_member_joined"
        case clanRequestAccepted   = "clan_request_accepted"
        case clanKicked            = "clan_kicked"
        case clanRoleChanged       = "clan_role_changed"
        case clanMuted             = "clan_muted"
        case clanWarStarted        = "clan_war_started"
        case clanWarEnded          = "clan_war_ended"
        case unknown
    }

    static func from(_ userInfo: [AnyHashable: Any]) -> NotificationPayload {
        let typeStr = userInfo["type"] as? String ?? ""
        return NotificationPayload(
            type:      NotificationType(rawValue: typeStr) ?? .unknown,
            clanId:    userInfo["clanId"] as? String,
            messageId: userInfo["messageId"] as? String,
            userId:    userInfo["userId"] as? String,
            raw:       userInfo
        )
    }
}

// MARK: - Device Endpoints
enum DeviceEndpoint {
    struct Register: Endpoint {
        typealias Response = EmptyData
        let deviceToken: String
        let platform: String
        var path: String { "/devices/register" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? {
            ["deviceToken": deviceToken, "platform": platform]
        }
    }

    struct Unregister: Endpoint {
        typealias Response = EmptyData
        var path: String { "/devices/unregister" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }
}
