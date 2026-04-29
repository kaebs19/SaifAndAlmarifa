//
//  GameAssets.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Assets/GameAssets.swift
//  أسماء الأصول (صور + أصوات) للمباراة — Type-safe enums

import SwiftUI

// MARK: - Power-Up Icons
enum PowerUpIcon: String, CaseIterable, Identifiable {
    case shield     = "powerup_shield"
    case freeze     = "powerup_freeze"
    case thunder    = "powerup_thunder"
    case hint       = "powerup_hint"
    case skip       = "powerup_skip"
    case double     = "powerup_double"
    case revive     = "powerup_revive"
    case fiftyFifty = "powerup_5050"
    case bird       = "powerup_bird"   // 🆕 عصفور — يضيّق المدى الرقمي
    case revealAnswer = "powerup_reveal" // 🆕 كشف الإجابة

    var id: String { rawValue }

    /// الاسم العربي
    var titleAr: String {
        switch self {
        case .shield:     return "درع"
        case .freeze:     return "تجميد"
        case .thunder:    return "ضعف الضرر"
        case .hint:       return "تلميح"
        case .skip:       return "تخطّي"
        case .double:     return "ضعف"
        case .revive:     return "إحياء"
        case .fiftyFifty: return "حذف إجابتين"
        case .bird:       return "عصفور"
        case .revealAnswer: return "كشف الإجابة"
        }
    }

    /// يربط بـ type من store items للاستخدام في الـ inventory
    var storeType: String {
        switch self {
        case .shield:     return "shield"
        case .freeze:     return "freeze_time"
        case .thunder:    return "double_damage"
        case .hint:       return "hint"
        case .skip:       return "skip"
        case .double:     return "double_damage"
        case .revive:     return "steal"
        case .fiftyFifty: return "eliminate_two"
        case .bird:       return "narrow_range"
        case .revealAnswer: return "reveal"   // ✅ مطابق لاسم backend
        }
    }

    /// SF Symbol fallback لو ما عندنا asset
    var sfSymbol: String? {
        switch self {
        case .bird:         return "bird.fill"
        case .revealAnswer: return "eye.fill"
        default:            return nil
        }
    }

    /// شرح موجز للـ tooltip
    var descriptionAr: String {
        switch self {
        case .shield:     return "يحمي قلعتك من الضربة التالية"
        case .freeze:     return "يضيف 5 ثوانٍ لوقتك"
        case .thunder:    return "ضربتك التالية تضرّ ضعف الـ HP"
        case .hint:       return "يكشف تلميحاً عن الإجابة"
        case .skip:       return "يتخطّى السؤال الحالي"
        case .double:     return "يضاعف نقاطك في السؤال التالي"
        case .revive:     return "يستعيد بعض الـ HP"
        case .fiftyFifty: return "يحذف خيارَين خاطئَين (MCQ فقط)"
        case .bird:       return "يضيّق المدى الرقمي للسؤال"
        case .revealAnswer: return "يكشف الإجابة الصحيحة (MCQ) أو رقماً منها"
        }
    }

    /// الصورة — يفضّل asset، fallback لـ SF Symbol
    @ViewBuilder
    var iconView: some View {
        if let symbol = sfSymbol {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
        } else {
            Image(rawValue)
                .resizable()
        }
    }

    /// الصورة من Assets (للحالات اللي عندها asset)
    var image: Image { Image(rawValue) }

    /// اسم ملف صوت التفعيل
    var soundName: String { rawValue }
}

// MARK: - Castle Sides
enum CastleSide: String {
    case player = "castle_gold_stage1"   // قلعتي الذهبية
    case enemy  = "castle_red_stage1"    // قلعة الخصم الحمراء

    var image: Image { Image(rawValue) }
}

// MARK: - Damage Overlay
enum DamageStage: String {
    case cracks  = "effect_cracks_light"  // ≤75% HP
    case smoke   = "effect_smoke"         // ≤50% HP
    case fire    = "effect_fire"          // ≤25% HP
    case rubble  = "effect_rubble"        // 0% HP

    var image: Image { Image(rawValue) }
}

// MARK: - Combat Effects
enum CombatEffect: String {
    case cannonball = "projectile_cannonball"
    case impact     = "effect_impact"

    var image: Image { Image(rawValue) }
}

// MARK: - UI Banners
enum UIBanner: String {
    case victory = "ui_banner_victory"
    case defeat  = "ui_mark_defeat"
    case scroll  = "ui_scroll_question"

    var image: Image { Image(rawValue) }
}

// MARK: - Sound Effects (custom MP3 files)
enum GameSound: String {
    // Match lifecycle
    case matchStart     = "match_start"
    case matchVictory   = "match_victory"
    case matchDefeat    = "match_defeat"

    // Question
    case questionAppear = "question_appear"
    case answerTap      = "answer_tap"
    case answerCorrect  = "answer_correct"
    case answerWrong    = "answer_wrong"

    // Combat
    case cannonFire     = "cannon_fire"
    case castleHit      = "castle_hit"
    case castleCollapse = "castle_collapse"

    // Timer
    case tickUrgent     = "tick_urgent"
    case heartbeat      = "heartbeat"
}
