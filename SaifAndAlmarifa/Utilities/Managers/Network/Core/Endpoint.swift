//
//  Endpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/Endpoint.swift
//  بروتوكول Endpoint - كل endpoint يُعرّف:
//    - النوع المُتوقع للاستجابة (Response) عبر associatedtype
//    - المسار والـ HTTP method
//    - البيانات المُرسَلة (اختياري)
//    - هل يحتاج مصادقة

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

// MARK: - Endpoint Protocol
protocol Endpoint {
    /// نوع البيانات المُتوقَع في `APIResponse<T>.data`
    associatedtype Response: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Encodable? { get }
    var requiresAuth: Bool { get }
    var headers: [String: String]? { get }
}

// MARK: - Default Values
extension Endpoint {
    var queryItems: [URLQueryItem]? { nil }
    var body: Encodable? { nil }
    var requiresAuth: Bool { false }
    var headers: [String: String]? { nil }
}
