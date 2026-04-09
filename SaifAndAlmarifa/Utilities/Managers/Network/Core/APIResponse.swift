//
//  APIResponse.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/APIResponse.swift
//  غلاف الاستجابة العام لكل الـ endpoints
//  الشكل: { success, message, data, errors }

import Foundation

// MARK: - API Response
/// الاستجابة الموحدة من الـ backend
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T?
    let errors: [String]?
}

// MARK: - Empty Data
/// يُستخدم للـ endpoints التي لا تُرجع data (مثل forgot-password)
struct EmptyData: Decodable {}

// MARK: - Unwrap Helper
extension APIResponse {
    /// فك الغلاف والحصول على `data` مباشرة
    /// - يرمي `APIError.apiError` إذا كان `success = false` أو `data = nil`
    func unwrap() throws -> T {
        guard success, let data else {
            throw APIError.apiError(
                message: message ?? "حدث خطأ غير متوقع",
                errors: errors
            )
        }
        return data
    }
}
