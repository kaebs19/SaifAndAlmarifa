//
//  SaifAndAlmarifaApp.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 03/04/2026.
//

import SwiftUI
import SwiftData

@main
struct SaifAndAlmarifaApp: App {

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
        // تسجيل الخطوط المخصصة (Cairo + Poppins) عند إقلاع التطبيق
        FontRegistrar.registerAll()
    }

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ContentView()
                // فرض اتجاه RTL للعربية
                .environment(\.layoutDirection, .rightToLeft)
                // تطبيق ثيم المستخدم (System/Light/Dark)
                .applyTheme()
                // معالجة callback تسجيل الدخول عبر Google
                .onOpenURL { url in
                    GoogleSignInManager.handle(url: url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
