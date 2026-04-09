//
//  APIConfig.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/APIConfig.swift
//  إعدادات API - Base URL, Timeouts, Headers

import Foundation

// MARK: - API Config
enum APIConfig {

    // MARK: - Environment
    enum Environment {
        case development
        case staging
        case production

        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:5001/api/v1"
            case .staging:
                return "https://staging.saifiq.com/api/v1"
            case .production:
                return "https://api.saifiq.com/api/v1"
            }
        }
    }

    // MARK: - Current Environment
    #if DEBUG
    static let environment: Environment = .development
    #else
    static let environment: Environment = .production
    #endif

    // MARK: - Base URL
    static var baseURL: String { environment.baseURL }

    // MARK: - Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60

    // MARK: - Default Headers
    static var defaultHeaders: [String: String] {
        [
            "Content-Type":  "application/json",
            "Accept":        "application/json",
            "Accept-Language": "ar"
        ]
    }
}
