//
//  NetworkManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/NetworkManager.swift
//  العميل الأساسي لكل طلبات الـ API (async/await)
//  - يفك غلاف APIResponse<T> تلقائياً
//  - يقرأ التوكن من Keychain مباشرة (غير مُرتبط بـ AuthManager)

import Foundation

// MARK: - Network Manager
final class NetworkManager: NetworkClient {

    // MARK: - Singleton
    static let shared = NetworkManager()

    // MARK: - Dependencies
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let keychain: KeychainManager

    // MARK: - Init
    init(
        session: URLSession? = nil,
        keychain: KeychainManager = .shared
    ) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest  = APIConfig.requestTimeout
            config.timeoutIntervalForResource = APIConfig.resourceTimeout
            config.waitsForConnectivity = true
            self.session = URLSession(configuration: config)
        }

        self.keychain = keychain

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    // MARK: - Public API (NetworkClient)

    /// إرسال طلب يُرجع `E.Response` مباشرة (بعد فك APIResponse<T>)
    func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        let data = try await sendWithAuthRetry(endpoint)

        // فك APIResponse<E.Response> واستخراج data
        do {
            let wrapper = try decoder.decode(APIResponse<E.Response>.self, from: data)
            return try wrapper.unwrap()
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingFailed(String(describing: error))
        }
    }

    /// إرسال طلب بدون الاهتمام بالبيانات الراجعة
    @discardableResult
    func requestVoid<E: Endpoint>(_ endpoint: E) async throws -> String? {
        let data = try await sendWithAuthRetry(endpoint)

        // نحاول قراءة الرسالة فقط (data قد تكون null)
        if let wrapper = try? decoder.decode(APIResponse<EmptyData>.self, from: data) {
            guard wrapper.success else {
                throw APIError.apiError(
                    message: wrapper.message ?? "حدث خطأ",
                    errors: wrapper.errors
                )
            }
            return wrapper.message
        }
        return nil
    }

    // MARK: - Private

    /// يرسل الطلب، وعند 401 لطلب يحتاج مصادقة: يحاول تجديد التوكن مرة واحدة
    /// ثم يعيد المحاولة. هذا يمنع تسجيل الخروج عند مجرّد انتهاء صلاحية الـ access.
    private func sendWithAuthRetry<E: Endpoint>(_ endpoint: E) async throws -> Data {
        var urlRequest = try buildURLRequest(from: endpoint)

        #if DEBUG
        logRequest(urlRequest)
        #endif

        var (data, response) = try await send(urlRequest)

        #if DEBUG
        logResponse(data: data, response: response)
        #endif

        // 401 لطلب مُصادَق → جرّب التجديد مرة واحدة قبل اعتبار الجلسة منتهية
        if endpoint.requiresAuth, isUnauthorized(response) {
            let usedToken = keychain.get(.authToken)
            let refreshed = await TokenRefreshCoordinator.shared.refresh(afterFailureWith: usedToken)

            if refreshed {
                // أعِد بناء الطلب ليحمل التوكن المجدّد، ثم أعِد الإرسال
                urlRequest = try buildURLRequest(from: endpoint)

                #if DEBUG
                logRequest(urlRequest)
                #endif

                (data, response) = try await send(urlRequest)

                #if DEBUG
                logResponse(data: data, response: response)
                #endif
            }
            // إن فشل التجديد، نترك validate() أدناه يطلق SessionExpiryHandler (تسجيل خروج)
        }

        // التحقق النهائي: 401 هنا (بعد فشل التجديد أو استمراره) = جلسة منتهية فعلاً
        try validate(response: response, data: data)
        return data
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw mapURLError(error)
        }
    }

    private func isUnauthorized(_ response: URLResponse) -> Bool {
        (response as? HTTPURLResponse)?.statusCode == 401
    }

    private func buildURLRequest<E: Endpoint>(from endpoint: E) throws -> URLRequest {
        guard var components = URLComponents(string: APIConfig.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Default headers
        APIConfig.defaultHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Custom headers (per-endpoint)
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Auth header (يُقرأ من Keychain مباشرة)
        if endpoint.requiresAuth, let token = keychain.get(.authToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Body
        if let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingFailed
            }
        }

        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) { return }

        // محاولة قراءة رسالة الخطأ من الغلاف
        let wrapper = try? decoder.decode(APIResponse<EmptyData>.self, from: data)

        // ✨ 401 → امسح الجلسة وارجع لشاشة الدخول
        if httpResponse.statusCode == 401 {
            Task { @MainActor in
                SessionExpiryHandler.shared.handleExpiry()
            }
        }

        throw APIError.from(
            statusCode: httpResponse.statusCode,
            apiMessage: wrapper?.message,
            errors: wrapper?.errors
        )
    }

    private func mapURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .noInternet
        case .timedOut:
            return .timeout
        default:
            return .unknown(error.localizedDescription)
        }
    }

    // MARK: - Logging
    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("⬆️ [Request] \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body),
           let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str  = String(data: data, encoding: .utf8) {
            print("   Body: \(str)")
        }
    }

    private func logResponse(data: Data, response: URLResponse) {
        guard let http = response as? HTTPURLResponse else { return }
        let status = http.statusCode
        let icon = (200...299).contains(status) ? "✅" : "❌"
        print("\(icon) [Response] \(status) \(http.url?.absoluteString ?? "?")")
        if let str = String(data: data, encoding: .utf8), !str.isEmpty {
            print("   \(str.prefix(500))")
        }
    }
    #endif
}
