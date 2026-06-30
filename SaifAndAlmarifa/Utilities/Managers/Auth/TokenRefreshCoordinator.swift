//
//  TokenRefreshCoordinator.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Auth/TokenRefreshCoordinator.swift
//  منسّق تجديد التوكن — يضمن طلب تجديد واحد فقط حتى لو فشلت عدة طلبات بـ 401
//  في نفس اللحظة (single-flight). يتصل بـ /auth/refresh مباشرةً (URLSession خام)
//  حتى لا يمرّ عبر NetworkManager ويتجنّب التكرار اللانهائي.
//

import Foundation

actor TokenRefreshCoordinator {

    // MARK: - Singleton
    static let shared = TokenRefreshCoordinator()
    private init() {}

    // MARK: - Dependencies
    private let keychain = KeychainManager.shared

    // MARK: - State
    /// طلب التجديد الجاري (إن وُجد) — يضمن أن كل الطلبات المتزامنة تنتظر نفسه
    private var inFlight: Task<Bool, Never>?

    // MARK: - API

    /// يحاول تجديد التوكن مرة واحدة.
    /// - Parameter tokenUsed: التوكن الذي فشل به الطلب الأصلي — يُستخدم لكشف
    ///   ما إذا كان طلبٌ آخر قد جدّد التوكن بالفعل أثناء انتظارنا.
    /// - Returns: `true` إذا أصبح لدينا توكن صالح جديد (إما جدّدناه أو جدّده غيرنا).
    func refresh(afterFailureWith tokenUsed: String?) async -> Bool {
        // هل جدّد طلبٌ آخر التوكن بالفعل؟ (التوكن الحالي يختلف عن الذي فشلنا به)
        if let current = keychain.get(.authToken), current != tokenUsed {
            return true
        }

        // إن كان هناك تجديد جارٍ، انتظر نتيجته بدل بدء تجديد جديد
        if let inFlight {
            return await inFlight.value
        }

        let task = Task { await self.performRefresh() }
        inFlight = task
        let result = await task.value
        inFlight = nil
        return result
    }

    // MARK: - Private

    private func performRefresh() async -> Bool {
        guard let refreshToken = keychain.get(.refreshToken),
              let url = URL(string: APIConfig.baseURL + "/auth/refresh") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        APIConfig.defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: ["refreshToken": refreshToken]
        )

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return false
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let wrapper = try decoder.decode(APIResponse<AuthData>.self, from: data)
            guard wrapper.success, let auth = wrapper.data else { return false }

            // خزّن الزوج الجديد (تدوير الـ refresh token = جلسة منزلقة)
            keychain.save(auth.token, for: .authToken)
            if let newRefresh = auth.refreshToken {
                keychain.save(newRefresh, for: .refreshToken)
            }
            return true
        } catch {
            return false
        }
    }
}
