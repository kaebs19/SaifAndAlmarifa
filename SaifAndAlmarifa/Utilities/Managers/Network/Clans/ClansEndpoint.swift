//
//  ClansEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Clans/ClansEndpoint.swift
//  endpoints نظام العشائر

import Foundation

enum ClansEndpoint {

    // MARK: - Clan CRUD
    struct Create: Endpoint {
        typealias Response = Clan
        let name: String
        let description: String?
        let badge: String?
        let color: String?
        var path: String { "/clans" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? {
            [
                "name": name,
                "description": description ?? "",
                "badge": badge ?? "",
                "color": color ?? ""
            ]
        }
    }

    struct My: Endpoint {
        typealias Response = Clan
        var path: String { "/clans/my" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct Detail: Endpoint {
        typealias Response = Clan
        let id: String
        var path: String { "/clans/\(id)" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct Search: Endpoint {
        typealias Response = [ClanRankEntry]
        let query: String
        var path: String { "/clans/search" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
        var queryItems: [URLQueryItem]? { [.init(name: "q", value: query)] }
    }

    struct Update: Endpoint {
        typealias Response = Clan
        let id: String
        let name: String?
        let description: String?
        let badge: String?
        let color: String?
        let isOpen: Bool?
        var path: String { "/clans/\(id)" }
        var method: HTTPMethod { .patch }
        var requiresAuth: Bool { true }
        var body: Encodable? {
            var d: [String: AnyEncodable] = [:]
            if let name { d["name"] = AnyEncodable(name) }
            if let description { d["description"] = AnyEncodable(description) }
            if let badge { d["badge"] = AnyEncodable(badge) }
            if let color { d["color"] = AnyEncodable(color) }
            if let isOpen { d["isOpen"] = AnyEncodable(isOpen) }
            return d
        }
    }

    struct Delete: Endpoint {
        typealias Response = EmptyData
        let id: String
        var path: String { "/clans/\(id)" }
        var method: HTTPMethod { .delete }
        var requiresAuth: Bool { true }
    }

    // MARK: - Membership
    struct Join: Endpoint {
        typealias Response = ClanJoinResponse
        let id: String
        var path: String { "/clans/\(id)/join" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct Leave: Endpoint {
        typealias Response = EmptyData
        let id: String
        var path: String { "/clans/\(id)/leave" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct Members: Endpoint {
        typealias Response = [ClanMember]
        let id: String
        var path: String { "/clans/\(id)/members" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct Kick: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let userId: String
        var path: String { "/clans/\(clanId)/members/\(userId)/kick" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct Promote: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let userId: String
        var path: String { "/clans/\(clanId)/members/\(userId)/promote" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct Demote: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let userId: String
        var path: String { "/clans/\(clanId)/members/\(userId)/demote" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct Transfer: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let userId: String
        var path: String { "/clans/\(clanId)/transfer/\(userId)" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    // MARK: - Join Requests
    struct Requests: Endpoint {
        typealias Response = [ClanJoinRequest]
        let id: String
        var path: String { "/clans/\(id)/requests" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct AcceptRequest: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let requestId: String
        var path: String { "/clans/\(clanId)/requests/\(requestId)/accept" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct RejectRequest: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let requestId: String
        var path: String { "/clans/\(clanId)/requests/\(requestId)/reject" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    // MARK: - Chat
    struct ChatList: Endpoint {
        typealias Response = ChatPage
        let id: String
        let beforeId: String?   // pagination cursor (رسائل أقدم من messageId)
        let limit: Int

        init(id: String, beforeId: String? = nil, limit: Int = 30) {
            self.id = id; self.beforeId = beforeId; self.limit = limit
        }

        var path: String { "/clans/\(id)/chat" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
        var queryItems: [URLQueryItem]? {
            var items = [URLQueryItem(name: "limit", value: "\(limit)")]
            if let beforeId { items.append(.init(name: "before", value: beforeId)) }
            return items
        }
    }

    struct SendMessage: Endpoint {
        typealias Response = ClanMessage
        let id: String
        let content: String
        let type: String  // text | announcement
        let replyToId: String?

        init(id: String, content: String, type: String, replyToId: String? = nil) {
            self.id = id; self.content = content; self.type = type; self.replyToId = replyToId
        }

        var path: String { "/clans/\(id)/chat" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? {
            var d: [String: AnyEncodable] = [
                "content": AnyEncodable(content),
                "type": AnyEncodable(type)
            ]
            if let replyToId { d["replyToId"] = AnyEncodable(replyToId) }
            return d
        }
    }

    struct SendGameCode: Endpoint {
        typealias Response = ClanMessage
        let id: String
        let roomCode: String
        var path: String { "/clans/\(id)/chat/game-code" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? { ["roomCode": roomCode] }
    }

    struct PinMessage: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let messageId: String
        var path: String { "/clans/\(clanId)/chat/\(messageId)/pin" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct ReactMessage: Endpoint {
        typealias Response = [MessageReaction]
        let clanId: String
        let messageId: String
        let emoji: String
        var path: String { "/clans/\(clanId)/chat/\(messageId)/react" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? { ["emoji": emoji] }
    }

    // MARK: - Admin Tools
    struct DeleteMessage: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let messageId: String
        var path: String { "/clans/\(clanId)/chat/\(messageId)" }
        var method: HTTPMethod { .delete }
        var requiresAuth: Bool { true }
    }

    struct ClearChat: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        var path: String { "/clans/\(clanId)/chat" }
        var method: HTTPMethod { .delete }
        var requiresAuth: Bool { true }
    }

    struct ReportMessage: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let messageId: String
        let reason: String
        var path: String { "/clans/\(clanId)/chat/\(messageId)/report" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? { ["reason": reason] }
    }

    struct MuteMember: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let userId: String
        let durationMinutes: Int   // 0 = رفع الكتم
        var path: String { "/clans/\(clanId)/members/\(userId)/mute" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? { ["durationMinutes": durationMinutes] }
    }

    struct UnmuteMember: Endpoint {
        typealias Response = EmptyData
        let clanId: String
        let userId: String
        var path: String { "/clans/\(clanId)/members/\(userId)/unmute" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct SetReadOnly: Endpoint {
        typealias Response = Clan
        let id: String
        let readOnly: Bool
        var path: String { "/clans/\(id)" }
        var method: HTTPMethod { .patch }
        var requiresAuth: Bool { true }
        var body: Encodable? { ["readOnly": readOnly] }
    }

    // MARK: - Treasury
    struct DonateToTreasury: Endpoint {
        typealias Response = TreasuryDonationResult
        let id: String
        let amount: Int
        var path: String { "/clans/\(id)/treasury/donate" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? { ["amount": amount] }
    }

    struct TreasuryHistory: Endpoint {
        typealias Response = [TreasuryTransaction]
        let id: String
        var path: String { "/clans/\(id)/treasury/history" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    // MARK: - Wars
    struct CurrentWar: Endpoint {
        typealias Response = ClanWar
        let id: String
        var path: String { "/clans/\(id)/wars/current" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    // MARK: - History / Feed
    struct Events: Endpoint {
        typealias Response = [ClanEvent]
        let id: String
        let limit: Int
        init(id: String, limit: Int = 50) { self.id = id; self.limit = limit }
        var path: String { "/clans/\(id)/events" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
        var queryItems: [URLQueryItem]? { [.init(name: "limit", value: "\(limit)")] }
    }

    // MARK: - Leaderboards
    struct Leaderboard: Endpoint {
        typealias Response = [ClanRankEntry]
        var path: String { "/clans/leaderboard" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct MembersLeaderboard: Endpoint {
        typealias Response = [ClanMember]
        let id: String
        var path: String { "/clans/\(id)/leaderboard" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }
}
