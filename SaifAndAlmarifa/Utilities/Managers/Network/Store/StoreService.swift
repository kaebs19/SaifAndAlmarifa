//
//  StoreService.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation

@MainActor
final class StoreService: APIService {
    static let shared = StoreService()
    let network: NetworkClient = NetworkManager.shared
    private init() {}

    func getItems() async throws -> [StoreItem] {
        try await network.request(StoreEndpoint.Items())
    }

    func buy(itemType: String) async throws -> PurchaseResult {
        try await network.request(StoreEndpoint.Buy(itemType: itemType))
    }

    func getInventory() async throws -> [InventoryItem] {
        try await network.request(StoreEndpoint.Inventory())
    }
}
