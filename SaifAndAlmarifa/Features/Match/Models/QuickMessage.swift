//
//  QuickMessage.swift
//  SaifAndAlmarifa
//
//  Preset chat + emoji reactions during match
//

import Foundation

// MARK: - Quick Message

struct QuickMessage: Identifiable, Equatable {
    let id: UUID = UUID()
    let fromUserId: String
    let kind: Kind
    let value: String          // preset key OR emoji glyph
    let sentAt: Date

    enum Kind: String { case preset, emoji }

    /// Localized text to render in the bubble
    var displayText: String {
        switch kind {
        case .emoji:  return value
        case .preset: return QuickMessagePreset(rawValue: value)?.text ?? value
        }
    }
}

// MARK: - Preset Catalog (whitelisted on backend)

enum QuickMessagePreset: String, CaseIterable {
    // Friendly
    case salam          // "سلام عليكم"
    case goodLuck       // "حظ موفق 🍀"
    case wellPlayed     // "أحسنت!"
    case gg             // "GG 🎮"
    case thanksMatch    // "شكراً للمباراة"
    // Trash talk (light)
    case iChallengeYou  // "اتحداك!"
    case beatMeIfYouCan // "اتحداك تهزمني 💪"
    case iWillWin       // "أنا بفوز 🏆"
    case tooEasy        // "هذي سهلة 😏"
    case focus          // "تركيز!"
    // Reactions
    case beCareful      // "احذر! ⚠️"
    case haha           // "ههه 😂"
    case sad            // "😢"
    case didntExpect    // "ما توقعت 😮"
    case comeOn         // "هياا! ⚡"

    var text: String {
        switch self {
        case .salam:           return "سلام عليكم"
        case .goodLuck:        return "حظ موفق 🍀"
        case .wellPlayed:      return "أحسنت!"
        case .gg:              return "GG 🎮"
        case .thanksMatch:     return "شكراً للمباراة"
        case .iChallengeYou:   return "اتحداك!"
        case .beatMeIfYouCan:  return "اتحداك تهزمني 💪"
        case .iWillWin:        return "أنا بفوز 🏆"
        case .tooEasy:         return "هذي سهلة 😏"
        case .focus:           return "تركيز!"
        case .beCareful:       return "احذر! ⚠️"
        case .haha:            return "ههه 😂"
        case .sad:             return "😢"
        case .didntExpect:     return "ما توقعت 😮"
        case .comeOn:          return "هياا! ⚡"
        }
    }
}

// MARK: - Emoji Catalog (whitelisted on backend)

enum QuickEmojiCatalog {
    static let all: [String] = ["👍", "😂", "🔥", "💪", "👏", "🎉", "😮", "⚡", "😢", "👀", "⚔️", "🏆"]
}
