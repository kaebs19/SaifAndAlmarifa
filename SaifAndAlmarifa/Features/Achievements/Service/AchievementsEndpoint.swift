//
//  AchievementsEndpoint.swift
//  SaifAndAlmarifa
//

import Foundation

enum AchievementsEndpoint {
    /// GET /achievements — قائمة كاملة + حالة فتحي
    struct ListMine: Endpoint {
        typealias Response = [Achievement]
        var path: String { "/achievements" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    /// GET /achievements/catalog — للعرض قبل تسجيل الدخول
    struct Catalog: Endpoint {
        typealias Response = [Achievement]
        var path: String { "/achievements/catalog" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { false }
    }
}
