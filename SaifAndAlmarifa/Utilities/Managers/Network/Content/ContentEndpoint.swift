//
//  ContentEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Content/ContentEndpoint.swift

import Foundation

// MARK: - Content Endpoints (عامة — لا تحتاج auth)
enum ContentEndpoint {

    struct GetPage: Endpoint {
        typealias Response = ContentPageData
        let pageKey: ContentPageKey

        var path: String { "/content/\(pageKey.rawValue)" }
        var method: HTTPMethod { .get }
    }
}
