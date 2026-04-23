//
//  SaifAndAlmarifaApp.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 03/04/2026.
//

import SwiftUI
import SwiftData
import UIKit
import FirebaseCore
import FirebaseMessaging

// MARK: - AppDelegate — تدوير الشاشة + Firebase Cloud Messaging
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // تهيئة Firebase
        FirebaseApp.configure()
        // تسجيل PushNotificationsManager كـ MessagingDelegate لاستقبال FCM token
        Messaging.messaging().delegate = PushNotificationsManager.shared
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationManager.shared.locked
    }

    // MARK: - APNs Token → Firebase (FCM يحتاجه داخلياً)
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Firebase يحول APNs token إلى FCM token تلقائياً
        Messaging.messaging().apnsToken = deviceToken
        #if DEBUG
        print("✅ [APNs] Token forwarded to Firebase")
        #endif
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            PushNotificationsManager.shared.didFailToRegister(error: error)
        }
    }
}

@main
struct SaifAndAlmarifaApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - Theme
    @StateObject private var themeManager = ThemeManager.shared

    // MARK: - SwiftData Container
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Init
    init() {
        FontRegistrar.registerAll()
        AdManager.configure()
    }

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ContentView()
                // فرض اتجاه RTL للعربية
                .environment(\.layoutDirection, .rightToLeft)
                // تطبيق ثيم المستخدم (System/Light/Dark)
                .applyTheme()
                // Custom scheme (saifiq://) + Google callback
                .onOpenURL { url in
                    if GoogleSignInManager.handle(url: url) { return }
                    DeepLinkManager.shared.handle(url)
                }
                // Universal Links (https://saifiq.halmanhaj.com/...)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        DeepLinkManager.shared.handle(url)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
