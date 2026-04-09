//
//  APIError.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/APIError.swift
//  أخطاء الشبكة + API

import Foundation

// MARK: - API Error
enum APIError: LocalizedError, Equatable {

    // MARK: Cases
    case invalidURL
    case invalidResponse
    case noInternet
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case rateLimited(message: String)
    case serverError(statusCode: Int)
    case decodingFailed(String)
    case encodingFailed
    case apiError(message: String, errors: [String]?)
    case unknown(String)

    // MARK: User-Facing Messages (عربي)
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "رابط غير صحيح"
        case .invalidResponse:
            return "استجابة غير صالحة من الخادم"
        case .noInternet:
            return "لا يوجد اتصال بالإنترنت"
        case .timeout:
            return "انتهت مهلة الاتصال، حاول مجدداً"
        case .unauthorized:
            return "انتهت الجلسة، يرجى تسجيل الدخول مجدداً"
        case .forbidden:
            return "ليس لديك صلاحية للوصول"
        case .notFound:
            return "لم يتم العثور على المورد المطلوب"
        case .rateLimited(let message):
            return message
        case .serverError(let code):
            return "خطأ في الخادم (\(code))"
        case .decodingFailed:
            return "فشل في قراءة البيانات"
        case .encodingFailed:
            return "فشل في إرسال البيانات"
        case .apiError(let message, _):
            return message
        case .unknown(let message):
            return message
        }
    }

    /// تفاصيل إضافية (للـ debugging أو إظهار تفاصيل الأخطاء)
    var details: [String]? {
        if case .apiError(_, let errors) = self { return errors }
        return nil
    }

    // MARK: - Equatable
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }

    // MARK: - Mapping from HTTP Status
    static func from(statusCode: Int, apiMessage: String?, errors: [String]?) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited(message: apiMessage ?? "محاولات كثيرة، انتظر قليلاً")
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .apiError(
                message: apiMessage ?? "حدث خطأ غير متوقع",
                errors: errors
            )
        }
    }
}
