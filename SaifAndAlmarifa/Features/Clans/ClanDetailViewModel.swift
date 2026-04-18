//
//  ClanDetailViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/ClanDetailViewModel.swift

import Foundation
import Combine
import UIKit

@MainActor
final class ClanDetailViewModel: ObservableObject {

    // MARK: - Inputs
    let clanId: String

    // MARK: - State
    @Published var clan: Clan?
    @Published var members: [ClanMember] = []
    @Published var leaderboard: [ClanMember] = []
    @Published var messages: [ClanMessage] = []
    @Published var requests: [ClanJoinRequest] = []

    @Published var messageText: String = ""
    @Published var selectedTab: Int = 0       // 0 شات, 1 الأعضاء, 2 الترتيب, 3 الطلبات, 4 معلومات
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var didLeave: Bool = false     // لتنبيه الشاشة الأم بالخروج
    @Published var typingUsernames: Set<String> = []  // من يكتب الآن
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreMessages: Bool = true
    @Published var replyingTo: ClanMessage?             // رسالة للرد عليها
    @Published var tappedMessageId: String?             // لإظهار الوقت
    @Published var showEmojiBar: Bool = false           // الشريط الإيموجي
    @Published var mentionQuery: String? = nil          // @ — نص البحث بعد @
    @Published var mentionRange: NSRange? = nil         // موقع @ في النص

    // MARK: - Dependencies
    private let service = ClansService.shared
    private let socket = AppSocketManager.shared
    private let toast = ToastManager.shared
    private let auth = AuthManager.shared

    // MARK: - Sockets
    private var cancellables = Set<AnyCancellable>()
    private var typingTimers: [String: Timer] = [:]
    private var typingThrottle: Date = .distantPast

    // MARK: - Derived
    /// الدور الخاص بي — يحاول من الـ response أولاً ثم من ClanStateManager (عشيرتي)
    var myRole: ClanRole? {
        if let role = clan?.myRole { return role }
        // احتياطي: إذا هذه عشيرتي، استخدم الدور المحفوظ globally
        if let myClan = ClanStateManager.shared.myClan, myClan.id == clanId {
            return myClan.myRole
        }
        return nil
    }
    var canManage: Bool { myRole?.canManage ?? false }
    var isOwner: Bool { myRole == .owner }
    /// هل أنا عضو؟ من الدور أو من ClanStateManager (مرجع ثابت)
    var isMember: Bool {
        if myRole != nil { return true }
        return ClanStateManager.shared.myClan?.id == clanId
    }
    var myId: String? { auth.currentUser?.id }

    var availableTabs: [String] {
        var tabs = ["الشات", "الإحصائيات", "الترتيب", "الأعضاء"]
        if canManage { tabs.append("الطلبات") }
        return tabs
    }

    // MARK: - Derived stats
    var onlineMembersCount: Int {
        members.filter { $0.isOnline == true }.count
    }

    /// MVP للأسبوع (أعلى نقاط)
    var mvp: ClanMember? {
        leaderboard.max(by: { $0.weeklyPoints < $1.weeklyPoints })
    }

    /// الدور الخاص بي في القائمة (لإبراز بطاقتي)
    var myMemberRecord: ClanMember? {
        members.first { $0.id == myId }
    }

    var membersByRole: [(role: ClanRole, members: [ClanMember])] {
        let owners  = members.filter { $0.role == .owner }
        let admins  = members.filter { $0.role == .admin }.sorted { $0.weeklyPoints > $1.weeklyPoints }
        let regular = members.filter { $0.role == .member }.sorted { $0.weeklyPoints > $1.weeklyPoints }
        var result: [(ClanRole, [ClanMember])] = []
        if !owners.isEmpty  { result.append((.owner, owners)) }
        if !admins.isEmpty  { result.append((.admin, admins)) }
        if !regular.isEmpty { result.append((.member, regular)) }
        return result
    }

    init(clanId: String) {
        self.clanId = clanId
        bindSockets()
    }

    // MARK: - Lifecycle
    func onAppear() async {
        socket.joinClanRoom(clanId)
        ClanStateManager.shared.enteringClanScreen(clanId)
        // فتح فوري من الكاش
        loadFromCache()
        await loadAll()
    }

    private func loadFromCache() {
        if let cached = LocalCache.load([ClanMessage].self, key: LocalCache.Keys.clanMessages(clanId)) {
            messages = cached
        }
    }

    private func saveToCache() {
        // احفظ آخر 50 رسالة فقط
        let toSave = Array(messages.prefix(50))
        LocalCache.save(toSave, key: LocalCache.Keys.clanMessages(clanId))
    }

    func onDisappear() {
        socket.leaveClanRoom(clanId)
        ClanStateManager.shared.leavingClanScreen()
        typingTimers.values.forEach { $0.invalidate() }
        typingTimers.removeAll()
        typingUsernames.removeAll()
    }

    // MARK: - Socket bindings
    private func bindSockets() {
        // رسالة جديدة
        socket.onClanMessage
            .sink { [weak self] payload in
                self?.handleIncomingMessage(payload)
            }
            .store(in: &cancellables)

        // حذف رسالة
        socket.onClanMessageDeleted
            .sink { [weak self] messageId in
                self?.messages.removeAll { $0.id == messageId }
            }
            .store(in: &cancellables)

        // تغيّر عضو (انضمام/مغادرة/دور)
        Publishers.Merge3(
            socket.onClanMemberJoined,
            socket.onClanMemberLeft,
            socket.onClanMemberRoleChanged
        )
        .sink { [weak self] payload in
            guard let self, (payload["clanId"] as? String) == self.clanId else { return }
            Task { await self.loadAll() }
        }
        .store(in: &cancellables)

        // يكتب الآن
        socket.onClanTyping
            .sink { [weak self] payload in
                self?.handleTyping(payload)
            }
            .store(in: &cancellables)

        // تحديث معلومات العشيرة
        socket.onClanUpdated
            .sink { [weak self] payload in
                guard let self, (payload["clanId"] as? String) == self.clanId else { return }
                Task { self.clan = try? await self.service.detail(self.clanId) }
            }
            .store(in: &cancellables)
    }

    private func handleIncomingMessage(_ payload: [String: Any]) {
        guard (payload["clanId"] as? String) == clanId else { return }
        // تحاول فك المحتوى لـ ClanMessage
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? JSONSerialization.data(withJSONObject: payload["message"] ?? payload),
              let msg = try? decoder.decode(ClanMessage.self, from: data) else { return }

        // تجنّب التكرار (الراسل يضيف محلياً قبل وصول الـ socket)
        if messages.contains(where: { $0.id == msg.id }) { return }
        messages.insert(msg, at: 0)
        saveToCache()

        // إخفاء "يكتب" للمُرسل
        if let uid = msg.user?.id, let username = msg.user?.username {
            typingUsernames.remove(username)
            typingTimers[uid]?.invalidate()
            typingTimers[uid] = nil
        }

        if msg.user?.id != myId { HapticManager.light() }
    }

    private func handleTyping(_ payload: [String: Any]) {
        guard (payload["clanId"] as? String) == clanId else { return }
        guard let userId = payload["userId"] as? String,
              let username = payload["username"] as? String,
              userId != myId else { return }

        typingUsernames.insert(username)

        // يختفي بعد 3 ثواني
        typingTimers[userId]?.invalidate()
        typingTimers[userId] = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.typingUsernames.remove(username)
                self?.typingTimers[userId] = nil
            }
        }
    }

    func notifyTyping() {
        let now = Date()
        guard now.timeIntervalSince(typingThrottle) > 2.0 else { return }
        typingThrottle = now
        socket.sendClanTyping(clanId)
    }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        async let c = safeDetail()
        async let m = safeMembers()
        async let lb = safeLeaderboard()
        async let ch = safeChat()
        let (cl, mm, lbs, chs) = await (c, m, lb, ch)
        clan = cl
        members = mm
        leaderboard = lbs
        messages = chs

        if canManage {
            requests = (try? await service.requests(clanId)) ?? []
        }
    }

    private func safeDetail() async -> Clan? { try? await service.detail(clanId) }
    private func safeMembers() async -> [ClanMember] { (try? await service.members(clanId)) ?? [] }
    private func safeLeaderboard() async -> [ClanMember] { (try? await service.membersLeaderboard(clanId)) ?? [] }
    private func safeChat() async -> [ClanMessage] {
        guard let page = try? await service.chat(clanId) else {
            hasMoreMessages = false
            return []
        }
        hasMoreMessages = page.hasMore
        return page.messages
    }

    // MARK: - Chat
    func sendMessage() async {
        let content = messageText.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }

        let isAdminMode = canManage && content.hasPrefix("!") // رسالة إعلان لو بدأت بـ !
        let type = isAdminMode ? "announcement" : "text"
        let finalContent = isAdminMode ? String(content.dropFirst()) : content
        let replyId = replyingTo?.id

        isSending = true
        defer { isSending = false }

        do {
            let msg = try await service.sendMessage(clanId, content: finalContent, type: type, replyToId: replyId)
            messageText = ""
            replyingTo = nil
            showEmojiBar = false
            mentionQuery = nil
            messages.insert(msg, at: 0)
            saveToCache()
            HapticManager.light()
        } catch let e as APIError {
            toast.error(e.errorDescription ?? "فشل الإرسال")
        } catch {
            toast.error("فشل الإرسال")
        }
    }

    /// إرسال رسالة سريعة (Preset)
    func sendPreset(_ preset: ChatPreset) async {
        messageText = preset.text
        await sendMessage()
    }

    /// إدراج إيموجي في النص
    func insertEmoji(_ emoji: String) {
        messageText += emoji
    }

    /// فتح الرد على رسالة
    func reply(to msg: ClanMessage) {
        replyingTo = msg
        HapticManager.light()
    }

    func cancelReply() {
        replyingTo = nil
    }

    /// نسخ نص رسالة
    func copy(_ msg: ClanMessage) {
        UIPasteboard.general.string = msg.content
        HapticManager.light()
        toast.info("تم النسخ")
    }

    /// mention عضو في النص
    func mention(_ member: ClanMember) {
        // لو كان في @partial نستبدلها، وإلا نضيف في النهاية
        if let range = mentionRange, let r = Range(range, in: messageText) {
            messageText.replaceSubrange(r, with: "@\(member.username) ")
        } else {
            messageText += "@\(member.username) "
        }
        mentionQuery = nil
        mentionRange = nil
    }

    /// عند تغيّر نص الإدخال — كشف @mention
    func onMessageTextChanged(_ new: String) {
        notifyTyping()

        // ابحث عن آخر @ قبل المؤشر
        let pattern = "@([\\p{L}0-9_]*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            mentionQuery = nil; return
        }
        let range = NSRange(new.startIndex..., in: new)
        if let match = regex.firstMatch(in: new, range: range),
           let whole = Range(match.range, in: new),
           let name = Range(match.range(at: 1), in: new) {
            mentionQuery = String(new[name])  // قد يكون ""
            mentionRange = NSRange(whole, in: new)
        } else {
            mentionQuery = nil
            mentionRange = nil
        }
    }

    /// قائمة الأعضاء المطابقة للـ mention query
    var mentionMatches: [ClanMember] {
        guard let q = mentionQuery else { return [] }
        if q.isEmpty { return Array(members.prefix(5)) }
        return members.filter { $0.username.lowercased().contains(q.lowercased()) }
    }

    func togglePin(_ msg: ClanMessage) async {
        do {
            try await service.pinMessage(clanId, messageId: msg.id)
            HapticManager.success()
            await refreshChat()
        } catch {
            toast.error("فشلت العملية")
        }
    }

    func refreshChat() async {
        messages = await safeChat()   // يحدّث hasMoreMessages من الـ envelope
        saveToCache()
    }

    /// جلب رسائل أقدم (pagination)
    func loadMoreMessages() async {
        guard !isLoadingMore, hasMoreMessages, let oldest = messages.last else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.chat(clanId, beforeId: oldest.id, limit: 30)
            let existing = Set(messages.map(\.id))
            let fresh = page.messages.filter { !existing.contains($0.id) }
            messages.append(contentsOf: fresh)
            hasMoreMessages = page.hasMore
        } catch {
            // عند خطأ، أوقف المحاولات لتجنّب loop
            hasMoreMessages = false
        }
    }

    // MARK: - Member actions
    func handleMember(_ member: ClanMember, action: ClanMemberRow.MemberAction) async {
        do {
            switch action {
            case .promote:
                try await service.promote(clanId, userId: member.id)
                toast.success("تمت الترقية")
            case .demote:
                try await service.demote(clanId, userId: member.id)
                toast.info("تم التنزيل")
            case .kick:
                try await service.kick(clanId, userId: member.id)
                toast.info("تم الطرد")
            case .transfer:
                try await service.transfer(clanId, to: member.id)
                toast.success("تم نقل الزعامة")
            }
            HapticManager.success()
            await loadAll()
        } catch let e as APIError {
            toast.error(e.errorDescription ?? "فشلت العملية")
        } catch {
            toast.error("فشلت العملية")
        }
    }

    // MARK: - Requests
    func accept(_ req: ClanJoinRequest) async {
        do {
            try await service.acceptRequest(clanId, requestId: req.id)
            requests.removeAll { $0.id == req.id }
            HapticManager.success()
            toast.success("تمت الموافقة")
            await loadAll()
        } catch { toast.error("فشلت الموافقة") }
    }

    func reject(_ req: ClanJoinRequest) async {
        do {
            try await service.rejectRequest(clanId, requestId: req.id)
            requests.removeAll { $0.id == req.id }
            toast.info("تم الرفض")
        } catch { toast.error("فشل الرفض") }
    }

    // MARK: - Join (لغير الأعضاء)
    @discardableResult
    func join() async -> Bool {
        do {
            let res = try await service.join(clanId)
            HapticManager.success()
            if res.isJoined {
                toast.success("انضممت إلى العشيرة")
                await loadAll()
                if let c = clan { ClanStateManager.shared.setMyClan(c) }
                return true
            } else {
                toast.info("تم إرسال طلب انضمام")
                return false
            }
        } catch let e as APIError {
            toast.error(e.errorDescription ?? "فشل الانضمام")
            return false
        } catch {
            toast.error("فشل الانضمام")
            return false
        }
    }

    // MARK: - Leave / Delete
    func leave() async {
        do {
            try await service.leave(clanId)
            HapticManager.success()
            toast.info("غادرت العشيرة")
            ClanStateManager.shared.removeMyClan()
            didLeave = true
        } catch let e as APIError {
            toast.error(e.errorDescription ?? "فشل")
        } catch { toast.error("فشل") }
    }

    func deleteClan() async {
        do {
            try await service.delete(clanId)
            HapticManager.success()
            toast.info("تم حذف العشيرة")
            ClanStateManager.shared.removeMyClan()
            didLeave = true
        } catch { toast.error("فشل الحذف") }
    }

    // MARK: - Settings update
    func toggleOpen() async {
        guard let c = clan else { return }
        let newVal = !(c.isOpen ?? true)
        do {
            clan = try await service.update(clanId, isOpen: newVal)
            HapticManager.success()
        } catch { toast.error("فشلت العملية") }
    }
}
