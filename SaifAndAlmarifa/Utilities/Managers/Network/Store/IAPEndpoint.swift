//
//  IAPEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation

// MARK: - IAP Verify
struct IAPVerifyRequest: Encodable {
    let productId: String
    let transactionId: String
}

struct IAPVerifyResponse: Decodable {
    let gemsAdded: Int
    let goldAdded: Int
    let newGems: Int
}

enum IAPEndpoint {
    struct Verify: Endpoint {
        typealias Response = IAPVerifyResponse
        let productId: String
        let transactionId: String

        var path: String { "/iap/verify" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var body: Encodable? {
            IAPVerifyRequest(productId: productId, transactionId: transactionId)
        }
    }
}
