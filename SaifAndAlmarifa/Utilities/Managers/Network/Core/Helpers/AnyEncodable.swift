//
//  AnyEncodable.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Core/Helpers/AnyEncodable.swift
//  Type erasure - يسمح بتشفير أي Encodable عبر واجهة موحدة

import Foundation

// MARK: - Any Encodable
/// Wrapper يسمح بتخزين/تمرير أي `Encodable` بدون معرفة نوعه الفعلي
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeFunc = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
