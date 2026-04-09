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
        let urlRequest = try buildURLRequest(from: endpoint)

        #if DEBUG
        logRequest(urlRequest)
        #endif

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw mapURLError(error)
        }

        #if DEBUG
        logResponse(data: data, response: response)
        #endif

        // تحقق من الـ HTTP status أولاً
        try validate(response: response, data: data)

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
        let urlRequest = try buildURLRequest(from: endpoint)

        #if DEBUG
        logRequest(urlRequest)
        #endif

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw mapURLError(error)
        }

        #if DEBUG
        logResponse(data: data, response: response)
        #endif

        try validate(response: response, data: data)

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
