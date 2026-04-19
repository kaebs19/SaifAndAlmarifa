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
    @Published var userStats: UserStats?
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
    @Published var invitedFriends: [Friend] = []          // الأصدقاء المدعوين في غرفة خاصة
    @Published var roomPlayers: [String] = []              // أسماء اللاعبين في الغرفة (حالياً)

    // MARK: - Lobby (الشاشة الموحّدة)
    @Published var activeLobby: GameMode? = nil
    @Published var matchFoundId: String? = nil

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
        // جلب عدد الإشعارات + الإحصائيات
        async let countFetch = service.getUnreadCount()
        async let statsFetch = service.getUserStats()
        unreadCount = (try? await countFetch) ?? 0
        userStats = try? await statsFetch
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

    /// يفتح شاشة اللوبي الموحّدة للوضع المطلوب ويشغّل العملية المناسبة
    func selectMode(_ mode: GameMode) {
        // نظّف الحالة السابقة
        resetLobbyState()
        activeLobby = mode
        pendingRoomMode = mode
        HapticManager.medium()

        switch mode {
        case .random1v1, .random4:
            startQueueSearch(mode)
        case .private1v1:
            createRoom(mode)
        case .challengeFriend, .friends4:
            // الأصدقاء يُحمَّلون أولاً، ثم يختار اللاعب من الـ lobby
            Task { await loadFriends() }
        }
    }

    /// يُستدعى عند إغلاق شاشة اللوبي
    func closeLobby() {
        // ألغِ أي طابور نشط
        if isSearching {
            socket.leaveQueue()
        }
        // ألغِ غرفة إذا كانت مفتوحة
        if roomCode != nil {
            socket.leaveRoom()
        }
        resetLobbyState()
    }

    private func resetLobbyState() {
        isSearching = false
        searchMode = nil
        roomCode = nil
        showRoomCode = false
        showFriendPicker = false
        invitedFriends = []
        roomPlayers = []
        pendingRoomMode = nil
        matchFoundId = nil
        activeLobby = nil
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
        // لو ما في غرفة بعد، أنشئها أولاً — سيتم تسجيل الصديق في `invitedFriends` وتُرسل الدعوة عند توفّر الكود
        if invitedFriends.contains(where: { $0.id == friend.id }) {
            toast.info("\(friend.username) مدعو بالفعل")
            return
        }

        invitedFriends.append(friend)

        if let code = roomCode {
            socket.inviteFriend(code: code, friendId: friend.id)
            toast.success("تم دعوة \(friend.username)")
        } else if let mode = pendingRoomMode {
            // أنشئ الغرفة الآن — الدعوات ستُرسل عند استقبال room:created
            createRoom(mode)
        }
    }

    /// إلغاء دعوة
    func uninviteFriend(_ friend: Friend) {
        invitedFriends.removeAll { $0.id == friend.id }
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
                self?.matchFoundId = matchId
                self?.toast.success("تم إيجاد مباراة!")
                self?.socket.joinMatch(matchId: matchId)
                // الإغلاق التلقائي للّوبي بعد ثانيتين
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self?.activeLobby = nil
                }
            }
            .store(in: &cancellables)

        // غرفة أُنشئت
        socket.onRoomCreated
            .sink { [weak self] data in
                guard let self else { return }
                if let code = data["code"] as? String {
                    self.roomCode = code
                    HapticManager.success()

                    // أرسل الدعوات للأصدقاء المختارين سابقاً
                    for friend in self.invitedFriends {
                        self.socket.inviteFriend(code: code, friendId: friend.id)
                    }
                }
            }
            .store(in: &cancellables)

        // لاعب انضم للغرفة
        socket.onRoomPlayerJoined
            .sink { [weak self] data in
                guard let self else { return }
                if let username = data["username"] as? String,
                   !self.roomPlayers.contains(username) {
                    self.roomPlayers.append(username)
                    HapticManager.light()
                }
            }
            .store(in: &cancellables)

        // لاعب غادر الغرفة
        socket.onRoomPlayerLeft
            .sink { [weak self] data in
                guard let self else { return }
                if let username = data["username"] as? String {
                    self.roomPlayers.removeAll { $0 == username }
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
