//
//  ClanPerks.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/Models/ClanPerks.swift
//  امتيازات العشيرة حسب المستوى — config محلي يطابق logic السيرفر

import SwiftUI

enum ClanPerk: Int, CaseIterable, Identifiable {
    case maxMembers30    = 1
    case dailyGoldBonus  = 2
    case storeDiscount   = 3
    case maxMembers50    = 4
    case exclusiveBadge  = 5

    var id: Int { rawValue }

    var unlockLevel: Int {
        switch self {
        case .maxMembers30:   return 1
        case .dailyGoldBonus: return 2
        case .storeDiscount:  return 2
        case .maxMembers50:   return 3
        case .exclusiveBadge: return 3
        }
    }

    var title: String {
        switch self {
        case .maxMembers30:   return "30 عضو كحد أقصى"
        case .dailyGoldBonus: return "ذهب يومي للأعضاء"
        case .storeDiscount:  return "خصم 10% على المتجر"
        case .maxMembers50:   return "50 عضو كحد أقصى"
        case .exclusiveBadge: return "شعار حصري"
        }
    }

    var description: String {
        switch self {
        case .maxMembers30:   return "القيمة الأساسية للعشيرة"
        case .dailyGoldBonus: return "كل عضو يحصل على 10 ذهب يومياً"
        case .storeDiscount:  return "الأعضاء يدفعون أقل في متجر العناصر"
        case .maxMembers50:   return "مساحة أكبر لأعضاء أكثر"
        case .exclusiveBadge: return "شعار مميّز بجنب اسم العشيرة"
        }
    }

    var icon: String {
        switch self {
        case .maxMembers30, .maxMembers50: return "person.2.fill"
        case .dailyGoldBonus:              return "sparkles"
        case .storeDiscount:               return "tag.fill"
        case .exclusiveBadge:              return "rosette"
        }
    }

    var color: Color {
        switch self {
        case .maxMembers30:   return Color(hex: "6366F1")
        case .dailyGoldBonus: return Color(hex: "FFD700")
        case .storeDiscount:  return Color(hex: "22C55E")
        case .maxMembers50:   return Color(hex: "8B5CF6")
        case .exclusiveBadge: return Color(hex: "EC4899")
        }
    }

    func isUnlocked(for level: Int) -> Bool { level >= unlockLevel }
}
