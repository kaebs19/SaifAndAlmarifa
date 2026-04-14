//
//  StoreViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation
import Combine

@MainActor
final class StoreViewModel: ObservableObject {

    @Published var items: [StoreItem] = []
    @Published var inventory: [InventoryItem] = []
    @Published var isLoading = false
    @Published var selectedTab = 0 // 0=المتجر, 1=المخزون

    private let service = StoreService.shared
    private let authService = AuthService.shared
    private let toast = ToastManager.shared

    var userGold: Int { AuthManager.shared.currentUser?.gold ?? 0 }
    var userGems: Int { AuthManager.shared.currentUser?.gems ?? 0 }

    func onAppear() async {
        isLoading = true; defer { isLoading = false }
        async let itemsFetch = service.getItems()
        async let inventoryFetch = service.getInventory()
        items = (try? await itemsFetch) ?? []
        inventory = (try? await inventoryFetch) ?? []
    }

    func buy(_ item: StoreItem) async {
        guard userGold >= item.goldCost else {
            toast.warning("لا يوجد ذهب كافي (تحتاج \(item.goldCost) 🪙)")
            HapticManager.error()
            return
        }

        isLoading = true; defer { isLoading = false }
        do {
            let result = try await service.buy(itemType: item.type)
            HapticManager.success()
            toast.success("تم شراء \(item.nameAr)", subtitle: "المتبقي: \(result.remainingGold) 🪙")
            // تحديث المخزون + بيانات المستخدم
            await onAppear()
            _ = try? await authService.getMe()
        } catch let error as APIError {
            HapticManager.error()
            toast.error(error.errorDescription ?? "فشل الشراء")
        } catch {
            toast.error(error.localizedDescription)
        }
    }

    func quantityOf(_ itemType: String) -> Int {
        inventory.first { $0.itemType == itemType }?.quantity ?? 0
    }
}
