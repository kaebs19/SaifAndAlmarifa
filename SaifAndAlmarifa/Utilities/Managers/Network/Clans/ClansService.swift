//
//  ClansService.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Clans/ClansService.swift
//  خدمة العشائر — غلاف نظيف على الـ endpoints

import Foundation

@MainActor
final class ClansService: APIService {
    static let shared = ClansService()
    let network: NetworkClient = NetworkManager.shared
    private init() {}

    // MARK: - Clan
    func create(name: String, description: String?, badge: String?, color: String?) async throws -> Clan {
        try await network.request(ClansEndpoint.Create(name: name, description: description, badge: badge, color: color))
    }

    func myClan() async throws -> Clan {
        try await network.request(ClansEndpoint.My())
    }

    func detail(_ id: String) async throws -> Clan {
        try await network.request(ClansEndpoint.Detail(id: id))
    }

    func search(_ query: String) async throws -> [ClanRankEntry] {
        try await network.request(ClansEndpoint.Search(query: query))
    }

    func update(_ id: String, name: String? = nil, description: String? = nil,
                badge: String? = nil, color: String? = nil, isOpen: Bool? = nil) async throws -> Clan {
        try await network.request(ClansEndpoint.Update(
            id: id, name: name, description: description, badge: badge, color: color, isOpen: isOpen
        ))
    }

    func delete(_ id: String) async throws {
        try await network.requestVoid(ClansEndpoint.Delete(id: id))
    }

    // MARK: - Membership
    func join(_ id: String) async throws -> ClanJoinResponse {
        try await network.request(ClansEndpoint.Join(id: id))
    }

    func leave(_ id: String) async throws {
        try await network.requestVoid(ClansEndpoint.Leave(id: id))
    }

    func members(_ id: String) async throws -> [ClanMember] {
        try await network.request(ClansEndpoint.Members(id: id))
    }

    func kick(_ clanId: String, userId: String) async throws {
        try await network.requestVoid(ClansEndpoint.Kick(clanId: clanId, userId: userId))
    }

    func promote(_ clanId: String, userId: String) async throws {
        try await network.requestVoid(ClansEndpoint.Promote(clanId: clanId, userId: userId))
    }

    func demote(_ clanId: String, userId: String) async throws {
        try await network.requestVoid(ClansEndpoint.Demote(clanId: clanId, userId: userId))
    }

    func transfer(_ clanId: String, to userId: String) async throws {
        try await network.requestVoid(ClansEndpoint.Transfer(clanId: clanId, userId: userId))
    }

    // MARK: - Requests
    func requests(_ id: String) async throws -> [ClanJoinRequest] {
        try await network.request(ClansEndpoint.Requests(id: id))
    }

    func acceptRequest(_ clanId: String, requestId: String) async throws {
        try await network.requestVoid(ClansEndpoint.AcceptRequest(clanId: clanId, requestId: requestId))
    }

    func rejectRequest(_ clanId: String, requestId: String) async throws {
        try await network.requestVoid(ClansEndpoint.RejectRequest(clanId: clanId, requestId: requestId))
    }

    // MARK: - Chat
    func chat(_ id: String, beforeId: String? = nil, limit: Int = 30) async throws -> ChatPage {
        try await network.request(ClansEndpoint.ChatList(id: id, beforeId: beforeId, limit: limit))
    }

    func sendMessage(_ id: String, content: String, type: String = "text", replyToId: String? = nil) async throws -> ClanMessage {
        try await network.request(ClansEndpoint.SendMessage(id: id, content: content, type: type, replyToId: replyToId))
    }

    func sendGameCode(_ id: String, roomCode: String) async throws -> ClanMessage {
        try await network.request(ClansEndpoint.SendGameCode(id: id, roomCode: roomCode))
    }

    func pinMessage(_ clanId: String, messageId: String) async throws {
        try await network.requestVoid(ClansEndpoint.PinMessage(clanId: clanId, messageId: messageId))
    }

    /// تفاعل (toggle) — يُرجع قائمة التفاعلات المحدّثة
    func reactMessage(_ clanId: String, messageId: String, emoji: String) async throws -> [MessageReaction] {
        try await network.request(ClansEndpoint.ReactMessage(clanId: clanId, messageId: messageId, emoji: emoji))
    }

    // MARK: - Admin
    func deleteMessage(_ clanId: String, messageId: String) async throws {
        try await network.requestVoid(ClansEndpoint.DeleteMessage(clanId: clanId, messageId: messageId))
    }

    func clearChat(_ clanId: String) async throws {
        try await network.requestVoid(ClansEndpoint.ClearChat(clanId: clanId))
    }

    func reportMessage(_ clanId: String, messageId: String, reason: String) async throws {
        try await network.requestVoid(ClansEndpoint.ReportMessage(clanId: clanId, messageId: messageId, reason: reason))
    }

    func muteMember(_ clanId: String, userId: String, durationMinutes: Int) async throws {
        try await network.requestVoid(ClansEndpoint.MuteMember(clanId: clanId, userId: userId, durationMinutes: durationMinutes))
    }

    func unmuteMember(_ clanId: String, userId: String) async throws {
        try await network.requestVoid(ClansEndpoint.UnmuteMember(clanId: clanId, userId: userId))
    }

    func setReadOnly(_ id: String, readOnly: Bool) async throws -> Clan {
        try await network.request(ClansEndpoint.SetReadOnly(id: id, readOnly: readOnly))
    }

    // MARK: - History
    func events(_ id: String, limit: Int = 50) async throws -> [ClanEvent] {
        try await network.request(ClansEndpoint.Events(id: id, limit: limit))
    }

    // MARK: - Treasury
    func donateToTreasury(_ id: String, amount: Int) async throws -> TreasuryDonationResult {
        try await network.request(ClansEndpoint.DonateToTreasury(id: id, amount: amount))
    }

    func treasuryHistory(_ id: String) async throws -> [TreasuryTransaction] {
        try await network.request(ClansEndpoint.TreasuryHistory(id: id))
    }

    // MARK: - Wars
    func currentWar(_ id: String) async throws -> ClanWar {
        try await network.request(ClansEndpoint.CurrentWar(id: id))
    }

    // MARK: - Leaderboards
    func topClans() async throws -> [ClanRankEntry] {
        try await network.request(ClansEndpoint.Leaderboard())
    }

    func membersLeaderboard(_ id: String) async throws -> [ClanMember] {
        try await network.request(ClansEndpoint.MembersLeaderboard(id: id))
    }
}
