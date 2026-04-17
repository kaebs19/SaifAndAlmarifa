//
//  LocalCache.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/LocalCache.swift
//  كاش محلي بسيط (UserDefaults + JSON) لأنماط stale-while-revalidate

import Foundation

/// كاش محلي نوعي. تحفظ بـ `Codable` وتسترجع بسرعة.
enum LocalCache {

    private static let prefix = "cache."
    private static let defaults = UserDefaults.standard
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()

    // MARK: - Public

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: prefix + key)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: prefix + key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    static func remove(key: String) {
        defaults.removeObject(forKey: prefix + key)
    }

    // MARK: - Clan-specific keys
    enum Keys {
        static let myClan = "clans.my"
        static let topClans = "clans.top"
        static func clanDetail(_ id: String) -> String { "clans.detail.\(id)" }
        static func clanMembers(_ id: String) -> String { "clans.members.\(id)" }
        static func clanMessages(_ id: String) -> String { "clans.messages.\(id)" }
    }
}
