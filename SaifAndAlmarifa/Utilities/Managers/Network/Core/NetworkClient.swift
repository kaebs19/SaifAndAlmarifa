//
//  NetworkClient.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/NetworkClient.swift
//  واجهة الشبكة المجردة - تسهّل الـ Mocking في الاختبارات

import Foundation

// MARK: - Network Client Protocol
/// عميل شبكة قابل للحقن والاختبار
/// - يُرجع مباشرة `E.Response` (بعد فك غلاف `APIResponse<T>`)
/// - يرمي `APIError` في حالة الفشل
protocol NetworkClient {
    /// إرسال طلب يُرجع بيانات من النوع المُحدَّد في الـ endpoint
    func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response

    /// إرسال طلب بدون الاهتمام بالبيانات الراجعة (يُرجع رسالة النجاح)
    @discardableResult
    func requestVoid<E: Endpoint>(_ endpoint: E) async throws -> String?
}
