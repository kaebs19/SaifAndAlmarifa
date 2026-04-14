//
//  StoreEndpoint.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation

enum StoreEndpoint {
    struct Items: Endpoint {
        typealias Response = [StoreItem]
        var path: String { "/store/items" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }

    struct Buy: Endpoint {
        typealias Response = PurchaseResult
        let itemType: String
        var path: String { "/store/items/\(itemType)/buy" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    struct Inventory: Endpoint {
        typealias Response = [InventoryItem]
        var path: String { "/store/inventory" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { true }
    }
}
