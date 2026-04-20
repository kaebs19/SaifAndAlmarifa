//
//  FriendsEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation

enum FriendsEndpoint {
    struct List: Endpoint { typealias Response = [Friend]; var path: String { "/friends" }; var method: HTTPMethod { .get }; var requiresAuth: Bool { true } }
    struct Requests: Endpoint { typealias Response = [FriendRequest]; var path: String { "/friends/requests" }; var method: HTTPMethod { .get }; var requiresAuth: Bool { true } }
    struct Search: Endpoint { typealias Response = [FriendSearchResult]; let query: String; var path: String { "/friends/search" }; var method: HTTPMethod { .get }; var queryItems: [URLQueryItem]? { [.init(name: "q", value: query)] }; var requiresAuth: Bool { true } }

    /// بحث عن لاعبين عامّاً (ليسوا أصدقاء بالضرورة)
    struct SearchUsers: Endpoint {
        typealias Response = [FriendSearchResult]
        let query: String
        var path: String { "/users/search" }
        var method: HTTPMethod { .get }
        var queryItems: [URLQueryItem]? { [.init(name: "q", value: query)] }
        var requiresAuth: Bool { true }
    }
    struct SendRequest: Endpoint { typealias Response = EmptyData; let userId: String; var path: String { "/friends/request" }; var method: HTTPMethod { .post }; var body: Encodable? { ["userId": userId] }; var requiresAuth: Bool { true } }
    struct AddByCode: Endpoint { typealias Response = EmptyData; let code: String; var path: String { "/friends/add-by-code" }; var method: HTTPMethod { .post }; var body: Encodable? { ["friendCode": code] }; var requiresAuth: Bool { true } }
    struct Accept: Endpoint { typealias Response = EmptyData; let id: String; var path: String { "/friends/\(id)/accept" }; var method: HTTPMethod { .patch }; var requiresAuth: Bool { true } }
    struct Reject: Endpoint { typealias Response = EmptyData; let id: String; var path: String { "/friends/\(id)/reject" }; var method: HTTPMethod { .patch }; var requiresAuth: Bool { true } }
    struct Remove: Endpoint { typealias Response = EmptyData; let id: String; var path: String { "/friends/\(id)" }; var method: HTTPMethod { .delete }; var requiresAuth: Bool { true } }
}

// MARK: - Models
struct FriendRequest: Decodable, Identifiable {
    let friendshipId: String; let id: String; let username: String; let avatarUrl: String?; let requestedAt: String?
}

struct FriendSearchResult: Decodable, Identifiable {
    let id: String; let username: String; let avatarUrl: String?; let level: Int?; let country: String?
}
