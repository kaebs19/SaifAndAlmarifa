//
//  MainViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import Foundation
import Combine

// MARK: - ViewModel الشاشة الرئيسية
@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - State
    @Published var selectedTab: MainTab = .home
    @Published var unreadCount: Int = 0
    @Published var isSearching: Bool = false
    @Published var searchMode: GameMode?
    @Published var canClaimDaily: Bool = false
    @Published var canSpin: Bool = false

    // MARK: - Room
    @Published var roomCode: String?
    @Published var showRoomCode: Bool = false
    @Published var showFriendPicker: Bool = false
    @Published var showJoinRoom: Bool = false
    @Published var friends: [Friend] = []
    @Published var pendingRoomMode: GameMode?

    // MARK: - Dependencies
    private let authManager = AuthManager.shared
    private let socket = AppSocketManager.shared
    private let service = MainService.shared
    private let toast = ToastManager.shared
    private var cancellables = Set<AnyCancellable>()

    var user: User? { authManager.currentUser }

    // MARK: - Init
    init() {
        setupSocketListeners()
    }

    // MARK: - تحميل البيانات
    func onAppear() async {
        // جلب عدد الإشعارات
        if let count = try? await service.getUnreadCount() {
            unreadCount = count
        }
        // حالة المكافأة اليومية
        if let status = try? await service.getDailyRewardStatus() {
            canClaimDaily = !status.claimed
        }
        // حالة العجلة
        if let status = try? await service.getSpinStatus() {
            canSpin = status.canSpin
        }
        // تأكد الاتصال بالسوكت
        if socket.state == .disconnected {
            socket.connect()
        }
    }

    // MARK: - ═══════════════ أوضاع اللعب ═══════════════

    func selectMode(_ mode: GameMode) {
        switch mode {
        case .random1v1, .random4:
            startQueueSearch(mode)
        case .private1v1:
            createRoom(mode)
        case .challengeFriend, .friends4:
            pendingRoomMode = mode
            Task { await loadFriends() }
            showFriendPicker = true
        }
    }

    // MARK: بحث عشوائي
    private func startQueueSearch(_ mode: GameMode) {
        isSearching = true
        searchMode = mode
        socket.joinQueue(mode: mode.socketMode)
    }

    func cancelSearch() {
        socket.leaveQueue()
        isSearching = false
        searchMode = nil
    }

    // MARK: إنشاء غرفة
    private func createRoom(_ mode: GameMode) {
        socket.createRoom(mode: mode.socketMode)
    }

    // MARK: الانضمام بكود
    func joinRoom(code: String) {
        guard !code.isEmpty else { return }
        socket.joinRoom(code: code)
        showJoinRoom = false
    }

    // MARK: دعوة صديق
    func inviteFriend(_ friend: Friend) {
        guard let code = roomCode else { return }
        socket.inviteFriend(code: code, friendId: friend.id)
        toast.info("تم إرسال الدعوة لـ \(friend.username)")
    }

    // MARK: تحميل الأصدقاء
    func loadFriends() async {
        do {
            friends = try await service.getFriends()
        } catch {
            friends = []
        }
    }

    // MARK: - ═══════════════ Socket Listeners ═══════════════

    private func setupSocketListeners() {
        // انضمام للطابور
        socket.onQueueJoined
            .sink { [weak self] in
                self?.isSearching = true
            }
            .store(in: &cancellables)

        // خطأ في الطابور
        socket.onQueueError
            .sink { [weak self] msg in
                self?.isSearching = false
                self?.searchMode = nil
                self?.toast.error(msg)
            }
            .store(in: &cancellables)

        // تم إيجاد مباراة
        socket.onMatchFound
            .sink { [weak self] data in
                self?.isSearching = false
                self?.searchMode = nil
                HapticManager.success()
                let matchId = data["matchId"] as? String ?? ""
                self?.toast.success("تم إيجاد مباراة!")
                // TODO: الانتقال لشاشة المباراة
                self?.socket.joinMatch(matchId: matchId)
            }
            .store(in: &cancellables)

        // غرفة أُنشئت
        socket.onRoomCreated
            .sink { [weak self] data in
                if let code = data["code"] as? String {
                    self?.roomCode = code
                    // إذا يحتاج صديق → أبقِ friend picker مفتوح
                    if self?.pendingRoomMode?.needsFriend != true {
                        self?.showRoomCode = true
                    }
                    HapticManager.success()
                }
            }
            .store(in: &cancellables)

        // خطأ في الغرفة
        socket.onRoomError
            .sink { [weak self] data in
                let msg = data["message"] as? String ?? "خطأ"
                self?.toast.error(msg)
            }
            .store(in: &cancellables)
    }
}
