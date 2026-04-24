//
//  SocketManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Socket/SocketManager.swift
//  مدير اتصال Socket.io — المصادقة عبر JWT + إدارة الاتصال

import Foundation
import Combine
import SocketIO

// MARK: - حالة الاتصال
enum SocketConnectionState: String {
    case disconnected
    case connecting
    case connected
}

// MARK: - Socket Manager
@MainActor
final class AppSocketManager: ObservableObject {

    // MARK: - Singleton
    static let shared = AppSocketManager()

    // MARK: - Published
    @Published private(set) var state: SocketConnectionState = .disconnected

    // MARK: - SocketIO
    private var manager: SocketIO.SocketManager?
    private var socket: SocketIOClient?

    // MARK: - Event Publishers (للـ ViewModels)
    let onConnected = PassthroughSubject<Void, Never>()
    let onDisconnected = PassthroughSubject<Void, Never>()
    let onQueueJoined = PassthroughSubject<Void, Never>()
    let onQueueLeft = PassthroughSubject<Void, Never>()
    let onQueueError = PassthroughSubject<String, Never>()
    let onMatchFound = PassthroughSubject<[String: Any], Never>()
    let onMatchStarted = PassthroughSubject<String, Never>()
    let onMatchQuestion = PassthroughSubject<[String: Any], Never>()
    let onMatchAnswerSubmitted = PassthroughSubject<[String: Any], Never>()
    let onMatchAttack = PassthroughSubject<[String: Any], Never>()
    let onMatchEliminated = PassthroughSubject<[String: Any], Never>()
    let onMatchItemUsed = PassthroughSubject<[String: Any], Never>()
    let onMatchItemEffect = PassthroughSubject<[String: Any], Never>()
    let onMatchEnded = PassthroughSubject<[String: Any], Never>()

    // Room Publishers
    let onRoomCreated = PassthroughSubject<[String: Any], Never>()
    let onRoomPlayerJoined = PassthroughSubject<[String: Any], Never>()
    let onRoomPlayerLeft = PassthroughSubject<[String: Any], Never>()
    let onRoomDisbanded = PassthroughSubject<[String: Any], Never>()
    let onRoomError = PassthroughSubject<[String: Any], Never>()
    let onRoomInvited = PassthroughSubject<[String: Any], Never>()
    let onRoomReadyState = PassthroughSubject<[String: Any], Never>()   // { code, readyUserIds }
    let onRoomAllReady = PassthroughSubject<String, Never>()            // clanId
    let onRoomKicked = PassthroughSubject<String, Never>()              // أنا تم طردي
    let onRoomChatMessage = PassthroughSubject<[String: Any], Never>()  // { code, message }
    let onRematchRequested = PassthroughSubject<[String: Any], Never>()   // { matchId, fromUserId }
    let onRematchAccepted = PassthroughSubject<[String: Any], Never>()    // { newMatchId }

    // Clan Publishers
    let onClanMessage = PassthroughSubject<[String: Any], Never>()          // رسالة جديدة
    let onClanMessageDeleted = PassthroughSubject<String, Never>()          // messageId
    let onClanChatCleared = PassthroughSubject<String, Never>()             // clanId
    let onClanMessageReaction = PassthroughSubject<[String: Any], Never>()  // { clanId, messageId, reactions }

    // Global stats
    let onOnlineCount = PassthroughSubject<Int, Never>()   // عدد اللاعبين المتصلين
    let onClanMemberJoined = PassthroughSubject<[String: Any], Never>()
    let onClanMemberLeft = PassthroughSubject<[String: Any], Never>()
    let onClanMemberRoleChanged = PassthroughSubject<[String: Any], Never>()
    let onClanTyping = PassthroughSubject<[String: Any], Never>()           // { userId, username }
    let onClanUpdated = PassthroughSubject<[String: Any], Never>()          // clan meta changed

    // MARK: - Dependencies
    private let keychain = KeychainManager.shared

    // MARK: - Init
    private init() {}

    // MARK: - ═══════════════ الاتصال ═══════════════

    /// الاتصال بالسيرفر مع JWT
    func connect() {
        guard state == .disconnected else { return }
        guard let token = keychain.get(.authToken) else {
            #if DEBUG
            print("⚠️ [Socket] No auth token — skipping connect")
            #endif
            return
        }

        state = .connecting

        let url = URL(string: APIConfig.socketURL)!
        manager = SocketIO.SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .forceWebsockets(true),
            .connectParams(["token": token]),
            .extraHeaders(["Authorization": "Bearer \(token)"])
        ])

        socket = manager?.defaultSocket
        setupListeners()
        socket?.connect()

        #if DEBUG
        print("🔌 [Socket] Connecting to \(APIConfig.socketURL)")
        #endif
    }

    /// قطع الاتصال
    func disconnect() {
        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager?.disconnect()
        manager = nil
        state = .disconnected

        #if DEBUG
        print("🔌 [Socket] Disconnected")
        #endif
    }

    /// إعادة الاتصال (عند تجديد التوكن مثلاً)
    func reconnect() {
        disconnect()
        connect()
    }

    // MARK: - ═══════════════ Queue ═══════════════

    /// الدخول لطابور البحث عن مباراة
    func joinQueue(mode: String = "1v1") {
        emit("queue:join", data: ["mode": mode])
    }

    /// الخروج من الطابور
    func leaveQueue() {
        emit("queue:leave")
    }

    // MARK: - ═══════════════ Room ═══════════════

    /// إنشاء غرفة خاصة
    func createRoom(mode: String) {
        emit("room:create", data: ["mode": mode])
    }

    /// الانضمام لغرفة بكود
    func joinRoom(code: String) {
        emit("room:join", data: ["code": code])
    }

    /// دعوة صديق لغرفة
    func inviteFriend(code: String, friendId: String) {
        emit("room:invite", data: ["code": code, "friendId": friendId])
    }

    /// مغادرة الغرفة
    func leaveRoom() {
        emit("room:leave")
    }

    /// استعداد اللاعب (toggle)
    func setReady(_ isReady: Bool) {
        emit("room:ready", data: ["ready": isReady])
    }

    /// الهوست يطرد لاعب
    func kickFromRoom(userId: String) {
        emit("room:kick", data: ["userId": userId])
    }

    /// إرسال رسالة في شات الغرفة
    func sendRoomMessage(_ content: String) {
        emit("room:chat-message", data: ["content": content])
    }

    // MARK: - ═══════════════ Match ═══════════════

    /// الانضمام لغرفة المباراة
    func joinMatch(matchId: String) {
        emit("match:join", data: ["matchId": matchId])
    }

    /// إرسال إجابة — مع زمن الإجابة بالميلي ثانية
    func submitAnswer(matchId: String, answer: String, timeMs: Int) {
        emit("match:answer", data: [
            "matchId": matchId,
            "answer": answer,
            "timeMs": timeMs
        ])
    }

    /// استخدام عنصر (درع مثلاً)
    func useItem(matchId: String, itemId: String) {
        emit("match:use-item", data: [
            "matchId": matchId,
            "itemId": itemId
        ])
    }

    /// طلب إعادة تحدي (بعد انتهاء المباراة)
    func requestRematch(matchId: String) {
        emit("match:rematch", data: ["matchId": matchId])
    }

    // MARK: - ═══════════════ Clan ═══════════════

    /// الانضمام لغرفة سوكِت الخاصة بالعشيرة (للاستماع للرسائل)
    func joinClanRoom(_ clanId: String) {
        emit("clan:join", data: ["clanId": clanId])
    }

    /// مغادرة غرفة السوكِت (عند الخروج من شاشة العشيرة)
    func leaveClanRoom(_ clanId: String) {
        emit("clan:leave", data: ["clanId": clanId])
    }

    /// إشعار "يكتب الآن"
    func sendClanTyping(_ clanId: String) {
        emit("clan:typing", data: ["clanId": clanId])
    }

    // MARK: - ═══════════════ Private ═══════════════

    /// إرسال حدث
    private func emit(_ event: String, data: [String: Any]? = nil) {
        guard let socket, socket.status == .connected else {
            #if DEBUG
            print("⚠️ [Socket] Not connected — cannot emit '\(event)'")
            #endif
            return
        }

        if let data {
            socket.emit(event, data)
        } else {
            socket.emit(event)
        }

        #if DEBUG
        print("⬆️ [Socket] emit '\(event)'")
        #endif
    }

    // MARK: - تسجيل المستمعين
    private func setupListeners() {
        guard let socket else { return }

        // ── الاتصال ──
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor in
                self?.state = .connected
                self?.onConnected.send()
                #if DEBUG
                print("✅ [Socket] Connected")
                #endif
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            Task { @MainActor in
                self?.state = .disconnected
                self?.onDisconnected.send()
                #if DEBUG
                print("❌ [Socket] Disconnected")
                #endif
            }
        }

        socket.on(clientEvent: .error) { _, items in
            #if DEBUG
            print("❌ [Socket] Error: \(items)")
            #endif
        }

        // ── Queue ──
        socket.on("queue:joined") { [weak self] _, _ in
            Task { @MainActor in self?.onQueueJoined.send() }
        }

        socket.on("queue:left") { [weak self] _, _ in
            Task { @MainActor in self?.onQueueLeft.send() }
        }

        socket.on("queue:error") { [weak self] data, _ in
            Task { @MainActor in
                let msg = (data.first as? [String: Any])?["message"] as? String ?? "خطأ"
                self?.onQueueError.send(msg)
            }
        }

        // ── Room ──
        socket.on("room:created") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomCreated.send(d) }
            }
        }

        socket.on("room:player-joined") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomPlayerJoined.send(d) }
            }
        }

        socket.on("room:player-left") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomPlayerLeft.send(d) }
            }
        }

        socket.on("room:disbanded") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomDisbanded.send(d) }
            }
        }

        socket.on("room:error") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomError.send(d) }
            }
        }

        socket.on("room:invited") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomInvited.send(d) }
            }
        }

        socket.on("room:ready-state") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomReadyState.send(d) }
            }
        }

        socket.on("room:all-ready") { [weak self] data, _ in
            Task { @MainActor in
                let code = (data.first as? [String: Any])?["code"] as? String ?? ""
                self?.onRoomAllReady.send(code)
            }
        }

        socket.on("room:kicked") { [weak self] data, _ in
            Task { @MainActor in
                let reason = (data.first as? [String: Any])?["reason"] as? String ?? "تم طردك"
                self?.onRoomKicked.send(reason)
            }
        }

        socket.on("room:chat-message") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRoomChatMessage.send(d) }
            }
        }

        // ── Match ──
        socket.on("match:found") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchFound.send(d) }
            }
        }

        socket.on("match:started") { [weak self] data, _ in
            Task { @MainActor in
                let matchId = (data.first as? [String: Any])?["matchId"] as? String ?? ""
                self?.onMatchStarted.send(matchId)
            }
        }

        socket.on("match:question") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchQuestion.send(d) }
            }
        }

        socket.on("match:answer-submitted") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchAnswerSubmitted.send(d) }
            }
        }

        socket.on("match:attack") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchAttack.send(d) }
            }
        }

        socket.on("match:eliminated") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchEliminated.send(d) }
            }
        }

        socket.on("match:item-used") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchItemUsed.send(d) }
            }
        }

        socket.on("match:item-effect") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchItemEffect.send(d) }
            }
        }

        socket.on("match:ended") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onMatchEnded.send(d) }
            }
        }

        socket.on("match:rematch-requested") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRematchRequested.send(d) }
            }
        }

        socket.on("match:rematch-accepted") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onRematchAccepted.send(d) }
            }
        }

        // ── Clan ──
        socket.on("clan:message") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onClanMessage.send(d) }
            }
        }

        socket.on("clan:message-deleted") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any], let id = d["messageId"] as? String {
                    self?.onClanMessageDeleted.send(id)
                }
            }
        }

        socket.on("clan:chat-cleared") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any], let id = d["clanId"] as? String {
                    self?.onClanChatCleared.send(id)
                }
            }
        }

        socket.on("clan:message-reaction") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onClanMessageReaction.send(d) }
            }
        }

        // Global online count
        socket.on("stats:online") { [weak self] data, _ in
            Task { @MainActor in
                let count = (data.first as? [String: Any])?["count"] as? Int
                    ?? (data.first as? Int) ?? 0
                self?.onOnlineCount.send(count)
            }
        }

        socket.on("clan:member-joined") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onClanMemberJoined.send(d) }
            }
        }

        socket.on("clan:member-left") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onClanMemberLeft.send(d) }
            }
        }

        socket.on("clan:member-role-changed") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onClanMemberRoleChanged.send(d) }
            }
        }

        socket.on("clan:typing") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onClanTyping.send(d) }
            }
        }

        socket.on("clan:updated") { [weak self] data, _ in
            Task { @MainActor in
                if let d = data.first as? [String: Any] { self?.onClanUpdated.send(d) }
            }
        }
    }
}
