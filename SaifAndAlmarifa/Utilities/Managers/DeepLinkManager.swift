//
//  DeepLinkManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/DeepLinkManager.swift
//  تحليل ومعالجة الروابط العميقة
//  - Universal Link: https://saifiq.halmanhaj.com/join/ABC123
//  - Custom scheme:  saifiq://join/ABC123

import Foundation
import Combine

@MainActor
final class DeepLinkManager: ObservableObject {

    static let shared = DeepLinkManager()

    /// يُبث عند استلام رابط ليفتح الشاشة المناسبة
    let onDeepLink = PassthroughSubject<DeepLink, Never>()

    private init() {}

    // MARK: - Handle URL
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard let link = parse(url) else { return false }
        onDeepLink.send(link)
        return true
    }

    // MARK: - Parse
    private func parse(_ url: URL) -> DeepLink? {
        // قبول: https://host/join/CODE  أو  saifiq://join/CODE
        let components = url.pathComponents.filter { $0 != "/" }

        // انضمام لغرفة
        if components.first?.lowercased() == "join",
           components.count >= 2 {
            let code = components[1]
            return .joinRoom(code: code)
        }

        // انضمام لعشيرة (مستقبلاً)
        if components.first?.lowercased() == "clan",
           components.count >= 2 {
            return .openClan(id: components[1])
        }

        return nil
    }
}

// MARK: - Deep Link Types
enum DeepLink {
    case joinRoom(code: String)
    case openClan(id: String)
}
