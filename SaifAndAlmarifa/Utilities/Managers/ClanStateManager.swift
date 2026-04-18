//
//  ClanStateManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/ClanStateManager.swift
//  إدارة حالة العشيرة بشكل global للوصول السريع من MainView
//  - يحمّل بيانات عشيرتي عند الدخول
//  - يتابع الرسائل غير المقروءة عبر Socket
//  - يُستخدم من TopBar و QuickActions للعرض الذكي

import Foundation
import Combine

@MainActor
final class ClanStateManager: ObservableObject {

    // MARK: - Singleton
    static let shared = ClanStateManager()

    // MARK: - Published
    @Published private(set) var myClan: Clan?
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastMessage: ClanMessage?   // آخر رسالة للعرض السريع

    // MARK: - State
    private var activeClanScreenId: String?      // إذا كان الشات مفتوح، ما نعدّ unread
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies
    private let service = ClansService.shared
    private let socket = AppSocketManager.shared

    // MARK: - UserDefaults keys
    private let unreadKey = "clan.unread.count"
    private let lastSeenKey = "clan.lastSeen.messageId"

    private init() {
        // استعادة العدّاد من UserDefaults
        unreadCount = UserDefaults.standard.integer(forKey: unreadKey)
        bindSockets()
    }

    // MARK: - Public

    /// يستدعى بعد تسجيل الدخول أو عند فتح التطبيق
    func loadMyClan() async {
        // الكاش أولاً
        if myClan == nil {
            myClan = LocalCache.load(Clan.self, key: LocalCache.Keys.myClan)
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let clan = try await service.myClan()
            myClan = clan
            LocalCache.save(clan, key: LocalCache.Keys.myClan)
            // انضم لغرفة socket حتى لو ما كانت الشاشة مفتوحة (نستقبل الرسائل)
            socket.joinClanRoom(clan.id)
            // آخر رسالة (أول عنصر في الـ API = الأحدث)
            if let page = try? await service.chat(clan.id, limit: 1),
               let latest = page.messages.first {
                lastMessage = latest
            }
        } catch APIError.notFound {
            clear()
        } catch {
            // احتفظ بالكاش
        }
    }

    /// عند تسجيل الخروج
    func clear() {
        if let id = myClan?.id { socket.leaveClanRoom(id) }
        myClan = nil
        unreadCount = 0
        lastMessage = nil
        UserDefaults.standard.removeObject(forKey: unreadKey)
        UserDefaults.standard.removeObject(forKey: lastSeenKey)
        LocalCache.remove(key: LocalCache.Keys.myClan)
    }

    /// يستدعى عند فتح شاشة Detail — توقف عدّ unread لهذه العشيرة
    func enteringClanScreen(_ clanId: String) {
        activeClanScreenId = clanId
        if clanId == myClan?.id {
            markAsRead()
        }
    }

    /// عند الخروج من شاشة Detail
    func leavingClanScreen() {
        activeClanScreenId = nil
    }

    /// تصفير العدّاد يدوياً
    func markAsRead() {
        unreadCount = 0
        UserDefaults.standard.set(0, forKey: unreadKey)
    }

    /// تم إنشاء عشيرة أو الانضمام
    func setMyClan(_ clan: Clan) {
        myClan = clan
        LocalCache.save(clan, key: LocalCache.Keys.myClan)
        socket.joinClanRoom(clan.id)
        markAsRead()
    }

    /// تم المغادرة أو الحذف
    func removeMyClan() {
        if let id = myClan?.id { socket.leaveClanRoom(id) }
        myClan = nil
        markAsRead()
        LocalCache.remove(key: LocalCache.Keys.myClan)
    }

    // MARK: - Private

    private func bindSockets() {
        // رسالة جديدة في شات عشيرتي
        socket.onClanMessage
            .sink { [weak self] payload in
                self?.handleIncomingMessage(payload)
            }
            .store(in: &cancellables)

        // عند إعادة الاتصال، إعادة الانضمام لغرفة عشيرتي
        socket.onConnected
            .sink { [weak self] in
                guard let self, let id = self.myClan?.id else { return }
                self.socket.joinClanRoom(id)
            }
            .store(in: &cancellables)

        // تحديث بيانات العشيرة
        socket.onClanUpdated
            .sink { [weak self] payload in
                guard let self, let myId = self.myClan?.id,
                      (payload["clanId"] as? String) == myId else { return }
                Task { await self.loadMyClan() }
            }
            .store(in: &cancellables)

        // حذف رسالة — لو كانت آخر رسالة، أعد الجلب
        socket.onClanMessageDeleted
            .sink { [weak self] messageId in
                guard let self, self.lastMessage?.id == messageId else { return }
                Task { await self.refreshLastMessage() }
            }
            .store(in: &cancellables)

        // مسح الشات — صفّر آخر رسالة
        socket.onClanChatCleared
            .sink { [weak self] clanId in
                guard let self, clanId == self.myClan?.id else { return }
                self.lastMessage = nil
            }
            .store(in: &cancellables)
    }

    /// إعادة جلب آخر رسالة (بعد حذف أو تنظيف)
    private func refreshLastMessage() async {
        guard let id = myClan?.id else { return }
        if let page = try? await service.chat(id, limit: 1) {
            lastMessage = page.messages.first
        } else {
            lastMessage = nil
        }
    }

    private func handleIncomingMessage(_ payload: [String: Any]) {
        guard let myId = myClan?.id,
              (payload["clanId"] as? String) == myId else { return }

        // فك الرسالة لعرضها في الـ preview
        let messageDict = (payload["message"] as? [String: Any]) ?? payload
        if let data = try? JSONSerialization.data(withJSONObject: messageDict) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let msg = try? decoder.decode(ClanMessage.self, from: data) {
                lastMessage = msg
            }
        }

        // إذا الشاشة مفتوحة حالياً، ما نزيد عداد
        if activeClanScreenId == myId { return }

        // ما نعدّ رسائل System
        let type = messageDict["type"] as? String
        if type == "system" { return }

        unreadCount += 1
        UserDefaults.standard.set(unreadCount, forKey: unreadKey)
    }
}
