//
//  NotificationsEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation

struct AppNotification: Decodable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: String
}

enum NotificationsEndpoint {
    struct List: Endpoint { typealias Response = [AppNotification]; var path: String { "/notifications" }; var method: HTTPMethod { .get }; var requiresAuth: Bool { true } }
    struct MarkRead: Endpoint { typealias Response = EmptyData; let id: String; var path: String { "/notifications/\(id)/read" }; var method: HTTPMethod { .patch }; var requiresAuth: Bool { true } }
    struct MarkAllRead: Endpoint { typealias Response = EmptyData; var path: String { "/notifications/read-all" }; var method: HTTPMethod { .patch }; var requiresAuth: Bool { true } }
}
