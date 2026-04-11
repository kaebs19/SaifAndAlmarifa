//
//  ContentService.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Content/ContentService.swift

import Foundation

// MARK: - خدمة صفحات المحتوى
@MainActor
final class ContentService: APIService {

    // MARK: - Singleton
    static let shared = ContentService()
    let network: NetworkClient = NetworkManager.shared
    private init() {}

    // MARK: - جلب صفحة محتوى
    func getPage(_ key: ContentPageKey) async throws -> ContentPageData {
        try await network.request(ContentEndpoint.GetPage(pageKey: key))
    }
}
