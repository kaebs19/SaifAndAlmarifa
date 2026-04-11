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

    // MARK: - ═══════════════ Match ═══════════════

    /// الانضمام لغرفة المباراة
    func joinMatch(matchId: String) {
        emit("match:join", data: ["matchId": matchId])
    }

    /// إرسال إجابة
    func submitAnswer(matchId: String, questionId: String, answer: String) {
        emit("match:answer", data: [
            "matchId": matchId,
            "questionId": questionId,
            "answer": answer
        ])
    }

    /// استخدام عنصر (درع مثلاً)
    func useItem(matchId: String, itemId: String) {
        emit("match:use-item", data: [
            "matchId": matchId,
            "itemId": itemId
        ])
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
    }
}
