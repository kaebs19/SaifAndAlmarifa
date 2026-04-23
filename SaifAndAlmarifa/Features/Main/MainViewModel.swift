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
    @Published var roomPlayers: [RoomPlayer] = []          // اللاعبون الحاليون في الغرفة
    @Published var roomShareLink: String?                  // رابط المشاركة (من السيرفر)

    // MARK: - Lobby (الشاشة الموحّدة)
    @Published var activeLobby: GameMode? = nil
    @Published var matchFoundId: String? = nil
    @Published var activeMatch: ActiveMatchContext? = nil   // MatchView يفتح عند تحديده
    @Published var roomCountdown: Int? = nil   // عدّ تنازلي قبل البدء (3, 2, 1)
    private var countdownTimer: Timer?

    // MARK: - Ready Check
    @Published var readyUserIds: Set<String> = []
    @Published var amIReady: Bool = false

    // MARK: - Room Chat
    @Published var roomMessages: [RoomChatMessage] = []

    // MARK: - Search Users (للدعوة)
    @Published var userSearchResults: [FriendSearchResult] = []
    @Published var isSearchingUsers: Bool = false

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
            // كل أوضاع الغرفة: أنشئ فوراً — المستخدم يقدر يشارك الكود
            // أو يدعو أصدقاء داخل اللوبي
            Task { await loadFriends() }
            createRoom(mode)
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
        roomShareLink = nil
        pendingRoomMode = nil
        matchFoundId = nil
        activeLobby = nil
        readyUserIds = []
        amIReady = false
        roomMessages = []
        userSearchResults = []
        cancelRoomCountdown()
    }

    // MARK: - ═══════ Ready Check ═══════

    func toggleReady() {
        amIReady.toggle()
        socket.setReady(amIReady)
        HapticManager.light()
    }

    // MARK: - ═══════ Kick Player ═══════

    func kick(_ player: RoomPlayer) {
        socket.kickFromRoom(userId: player.id)
        toast.info("تم طرد \(player.username)")
        HapticManager.warning()
    }

    // MARK: - ═══════ Room Chat ═══════

    func sendRoomMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        socket.sendRoomMessage(trimmed)
    }

    // MARK: - ═══════ Search Users ═══════

    func searchUsers(_ query: String) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else {
            userSearchResults = []
            return
        }
        isSearchingUsers = true
        defer { isSearchingUsers = false }
        userSearchResults = (try? await NetworkManager.shared.request(FriendsEndpoint.SearchUsers(query: q))) ?? []
    }

    /// دعوة لاعب (ليس صديق بالضرورة) — يحوّل SearchResult إلى Friend
    func inviteUser(_ user: FriendSearchResult) {
        let friend = Friend(
            friendshipId: nil,
            id: user.id,
            username: user.username,
            avatarUrl: user.avatarUrl,
            level: user.level,
            country: user.country,
            friendCode: nil,
            isOnline: nil
        )
        inviteFriend(friend)
    }

    // MARK: - Room Countdown (Auto-start)

    /// يُفحص بعد كل `room:player-joined` — إذا اكتملت الغرفة يبدأ countdown
    fileprivate func checkRoomFull() {
        guard let mode = activeLobby,
              !mode.isQueue,
              roomCountdown == nil else { return }

        let total = 1 + roomPlayers.count   // أنا + الآخرون
        if total >= mode.playersRequired {
            startRoomCountdown()
        }
    }

    private func startRoomCountdown() {
        cancelRoomCountdown()
        roomCountdown = 3
        SoundManager.play(.roomFull)
        HapticManager.heavy()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self else { t.invalidate(); return }
                if let c = self.roomCountdown, c > 1 {
                    self.roomCountdown = c - 1
                    SoundManager.play(.countdown)
                    HapticManager.light()
                } else {
                    t.invalidate()
                    self.roomCountdown = nil
                    // السيرفر سيبعث match:started تلقائياً عند اكتمال الغرفة.
                    // هذا فقط visual — لا إرسال socket هنا.
                }
            }
        }
    }

    fileprivate func cancelRoomCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        roomCountdown = nil
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

    /// إرسال كود الغرفة في شات العشيرة
    func shareRoomCodeToClan() async -> Bool {
        guard let code = roomCode else {
            toast.error("لا يوجد كود غرفة")
            return false
        }
        guard let clanId = ClanStateManager.shared.myClan?.id else {
            toast.error("أنت لست في عشيرة")
            return false
        }
        do {
            _ = try await ClansService.shared.sendGameCode(clanId, roomCode: code)
            HapticManager.success()
            toast.success("تم الإرسال في شات العشيرة")
            return true
        } catch let e as APIError {
            toast.error(e.errorDescription ?? "فشل الإرسال")
            return false
        } catch {
            toast.error("فشل الإرسال")
            return false
        }
    }

    /// نص المشاركة للـ iOS Share Sheet
    func shareMessage() -> String {
        guard let code = roomCode else { return "" }
        var text = """
        انضم لمباراتي في سيف المعرفة! 🗡️
        الكود: \(code)
        """
        if let link = roomShareLink {
            text += "\n\(link)"
        } else {
            text += "\nافتح التطبيق → الانضمام بكود → \(code)"
        }
        return text
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
                guard let self else { return }
                self.isSearching = false
                self.searchMode = nil
                SoundManager.play(.matchFound)
                HapticManager.success()
                let matchId = data["matchId"] as? String ?? ""
                self.matchFoundId = matchId
                self.toast.success("تم إيجاد مباراة!")

                // استخراج الخصم
                let opponentDict = (data["opponent"] as? [String: Any])
                    ?? (data["players"] as? [[String: Any]])?.first(where: { ($0["id"] as? String) != self.user?.id })
                    ?? [:]
                let opponent = MatchPlayer.from(opponentDict)
                    ?? MatchPlayer(id: "opponent", username: "الخصم", avatarUrl: nil, level: nil, hp: 100, score: 0)

                // انتقال للمباراة بعد عرض ثانيتين للبانر
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.activeLobby = nil
                    self.activeMatch = ActiveMatchContext(matchId: matchId, opponent: opponent)
                }
            }
            .store(in: &cancellables)

        // غرفة أُنشئت
        socket.onRoomCreated
            .sink { [weak self] data in
                guard let self else { return }
                if let code = data["code"] as? String {
                    self.roomCode = code
                    self.roomShareLink = data["shareLink"] as? String
                    HapticManager.success()

                    // بيانات اللاعبين الأوائل (لو الـ backend أرسلهم)
                    if let playersArr = data["players"] as? [[String: Any]] {
                        self.roomPlayers = playersArr.compactMap(RoomPlayer.from)
                            .filter { $0.id != self.user?.id }  // استبعد نفسي (مذكور بطريقة مختلفة)
                    }

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

                let beforeCount = self.roomPlayers.count

                // طريقة جديدة: players array كاملة
                if let playersArr = data["players"] as? [[String: Any]] {
                    self.roomPlayers = playersArr.compactMap(RoomPlayer.from)
                        .filter { $0.id != self.user?.id }
                }
                // طريقة تكميلية: player object فقط
                else if let playerDict = data["player"] as? [String: Any],
                        let player = RoomPlayer.from(playerDict),
                        player.id != self.user?.id,
                        !self.roomPlayers.contains(where: { $0.id == player.id }) {
                    self.roomPlayers.append(player)
                }

                // feedback فقط لو فيه لاعب جديد فعلاً
                if self.roomPlayers.count > beforeCount {
                    SoundManager.play(.playerJoined)
                    HapticManager.success()
                }

                // الغرفة ممتلأة الآن
                self.checkRoomFull()
            }
            .store(in: &cancellables)

        // لاعب غادر الغرفة
        socket.onRoomPlayerLeft
            .sink { [weak self] data in
                guard let self else { return }
                let beforeCount = self.roomPlayers.count
                if let userId = data["userId"] as? String {
                    self.roomPlayers.removeAll { $0.id == userId }
                } else if let playersArr = data["players"] as? [[String: Any]] {
                    self.roomPlayers = playersArr.compactMap(RoomPlayer.from)
                        .filter { $0.id != self.user?.id }
                }
                if self.roomPlayers.count < beforeCount {
                    SoundManager.play(.playerLeft)
                    HapticManager.warning()
                    // ألغِ countdown لو كانت شغّالة
                    self.cancelRoomCountdown()
                }
            }
            .store(in: &cancellables)

        // غرفة تفكّكت
        socket.onRoomDisbanded
            .sink { [weak self] data in
                guard let self else { return }
                let reason = data["reason"] as? String ?? "انتهت الغرفة"
                self.toast.info(reason)
                self.resetLobbyState()
            }
            .store(in: &cancellables)

        // دعوة لغرفة (من صديق)
        socket.onRoomInvited
            .sink { [weak self] data in
                guard let self else { return }
                let fromUser = (data["fromUser"] as? [String: Any])?["username"] as? String ?? "صديق"
                let code = data["code"] as? String ?? ""
                self.toast.info("\(fromUser) يدعوك لغرفة \(code)")
                HapticManager.success()
            }
            .store(in: &cancellables)

        // حالة الاستعداد
        socket.onRoomReadyState
            .sink { [weak self] data in
                guard let self else { return }
                if let arr = data["readyUserIds"] as? [String] {
                    self.readyUserIds = Set(arr)
                    if let myId = self.user?.id {
                        self.amIReady = self.readyUserIds.contains(myId)
                    }
                }
            }
            .store(in: &cancellables)

        // الكل جاهز — بدء المباراة
        socket.onRoomAllReady
            .sink { [weak self] _ in
                self?.checkRoomFull()  // يُشغّل countdown نفسه
            }
            .store(in: &cancellables)

        // تم طردي من الغرفة
        socket.onRoomKicked
            .sink { [weak self] reason in
                guard let self else { return }
                self.toast.error(reason)
                HapticManager.error()
                self.resetLobbyState()
            }
            .store(in: &cancellables)

        // رسالة شات في الغرفة
        socket.onRoomChatMessage
            .sink { [weak self] data in
                guard let self else { return }
                let payload = (data["message"] as? [String: Any]) ?? data
                if let msg = RoomChatMessage.from(payload) {
                    if !self.roomMessages.contains(where: { $0.id == msg.id }) {
                        self.roomMessages.append(msg)
                        if msg.userId != self.user?.id {
                            SoundManager.play(.messageReceived)
                        }
                    }
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
