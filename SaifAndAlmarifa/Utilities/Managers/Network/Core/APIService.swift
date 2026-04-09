//
//  APIService.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/APIService.swift
//  البروتوكول الأساسي لكل الـ API Services
//  يُلغي التكرار في تعريف NetworkClient dependency

import Foundation

// MARK: - API Service
/// كل خدمة API (AuthService, ProfileService, GamesService...) تتبع هذا البروتوكول
///
/// مثال:
/// ```swift
/// @MainActor
/// final class ProfileService: APIService {
///     static let shared = ProfileService()
///     let network: NetworkClient = NetworkManager.shared
///     private init() {}
/// }
/// ```
protocol APIService {
    var network: NetworkClient { get }
}
