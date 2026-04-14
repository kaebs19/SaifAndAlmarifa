//
//  StoreModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation
import SwiftUI

// MARK: - عنصر المتجر
struct StoreItem: Decodable, Identifiable {
    let id: String
    let type: String
    let nameAr: String
    let descriptionAr: String
    let goldCost: Int

    var icon: String {
        switch type {
        case "skip":           return "forward.fill"
        case "hint":           return "lightbulb.fill"
        case "shield":         return "shield.fill"
        case "eliminate_two":  return "xmark.circle.fill"
        case "freeze_time":   return "snowflake"
        case "double_damage": return "bolt.fill"
        case "steal":         return "hand.raised.fill"
        case "reveal":        return "eye.fill"
        default:              return "questionmark.circle"
        }
    }

    var color: Color {
        switch type {
        case "skip":           return .blue
        case "hint":           return .yellow
        case "shield":         return .green
        case "eliminate_two":  return .red
        case "freeze_time":   return .cyan
        case "double_damage": return .orange
        case "steal":         return .purple
        case "reveal":        return .mint
        default:              return .gray
        }
    }
}

// MARK: - نتيجة الشراء
struct PurchaseResult: Decodable {
    let itemType: String
    let quantity: Int
    let goldSpent: Int
    let remainingGold: Int
}

// MARK: - عنصر في المخزون
struct InventoryItem: Decodable, Identifiable {
    let itemType: String
    let quantity: Int
    var id: String { itemType }
}
