//
//  ClansHubViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/ClansHubViewModel.swift

import Foundation
import Combine

@MainActor
final class ClansHubViewModel: ObservableObject {

    // MARK: - State
    @Published var myClan: Clan?
    @Published var topClans: [ClanRankEntry] = []
    @Published var searchResults: [ClanRankEntry] = []
    @Published var searchText: String = ""

    @Published var isLoading: Bool = false
    @Published var isSearching: Bool = false
    @Published var hasLoaded: Bool = false

    // Tab: 0 = الترتيب, 1 = بحث
    @Published var selectedTab: Int = 0

    // MARK: - Dependencies
    private let service = ClansService.shared
    private let toast = ToastManager.shared

    // MARK: - Lifecycle
    func onAppear() async {
        // 1. عرض فوري من الكاش (بدون وميض)
        if !hasLoaded { loadFromCache() }
        // 2. جلب من الشبكة وتحديث الكاش
        await refresh()
    }

    func refresh() async {
        // isLoading فقط إذا ما عندنا بيانات (لا تخرب الـ UI المعروض من الكاش)
        let wasEmpty = myClan == nil && topClans.isEmpty
        if wasEmpty { isLoading = true }
        defer { isLoading = false; hasLoaded = true }

        async let clan = fetchMyClan()
        async let top = fetchTopClans()
        _ = await (clan, top)
    }

    private func loadFromCache() {
        myClan = LocalCache.load(Clan.self, key: LocalCache.Keys.myClan)
        topClans = LocalCache.load([ClanRankEntry].self, key: LocalCache.Keys.topClans) ?? []
    }

    private func fetchMyClan() async {
        do {
            let clan = try await service.myClan()
            myClan = clan
            LocalCache.save(clan, key: LocalCache.Keys.myClan)
        } catch APIError.notFound {
            myClan = nil
            LocalCache.remove(key: LocalCache.Keys.myClan)
        } catch {
            // الإبقاء على الكاش في حال خطأ شبكة
        }
    }

    private func fetchTopClans() async {
        guard let list = try? await service.topClans() else { return }
        topClans = list
        LocalCache.save(list, key: LocalCache.Keys.topClans)
    }

    // MARK: - Search
    func search() async {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { searchResults = []; return }
        isSearching = true
        defer { isSearching = false }
        searchResults = (try? await service.search(q)) ?? []
    }

    // MARK: - Join
    func join(_ entry: ClanRankEntry) async -> String? {
        do {
            let res = try await service.join(entry.id)
            HapticManager.success()
            if res.isJoined {
                toast.success("انضممت إلى \(entry.name)")
                await refresh()
                return entry.id
            } else {
                toast.info("تم إرسال طلب انضمام")
                return nil
            }
        } catch let e as APIError {
            HapticManager.error()
            toast.error(e.errorDescription ?? "فشل الانضمام")
            return nil
        } catch {
            HapticManager.error()
            toast.error("فشل الانضمام")
            return nil
        }
    }

    // MARK: - Create (called from CreateClanSheet)
    func handleCreated(_ clan: Clan) {
        myClan = clan
        ClanStateManager.shared.setMyClan(clan)
        HapticManager.success()
    }
}
