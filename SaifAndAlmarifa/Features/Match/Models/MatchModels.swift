//
//  MatchModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Models/MatchModels.swift
//  نماذج بيانات المباراة

import Foundation
import UIKit

// MARK: - مرحلة المباراة
enum MatchPhase: String, Decodable {
    case collection   // المرحلة 1 — تجميع القوة (4 أسئلة)
    case transition   // عرض نتائج المرحلة 1
    case battle       // المرحلة 2 — مواجهة (10 أسئلة)
    case ended

    var titleAr: String {
        switch self {
        case .collection: return "تجميع القوة"
        case .transition: return "نتائج المرحلة 1"
        case .battle:     return "المواجهة"
        case .ended:      return "انتهى"
        }
    }
}

// MARK: - نوع الإجابة
enum QuestionAnswerType: String, Decodable {
    case numericInput   // رقم
    case textInput      // نص
    case multipleChoice // (احتياط للقديم)

    var keyboardHint: UIKeyboardType {
        switch self {
        case .numericInput: return .numbersAndPunctuation
        case .textInput, .multipleChoice: return .default
        }
    }
}

// MARK: - سؤال في المباراة
struct MatchQuestion: Identifiable, Equatable {
    let id: String
    let text: String
    let answerType: QuestionAnswerType
    let phase: MatchPhase
    let options: [String]        // فارغة لو input
    let index: Int               // 1..total per phase
    let total: Int
    let timeLimit: Int
    var correctAnswer: String?   // النص الصحيح بعد الإرسال
    var correctIndex: Int?       // (احتياط للـ MC)
    var disabledIndices: Set<Int> = []

    var isInput: Bool { answerType == .numericInput || answerType == .textInput }

    static func from(_ dict: [String: Any]) -> MatchQuestion? {
        guard let id = dict["questionId"] as? String ?? dict["id"] as? String,
              let text = dict["text"] as? String ?? dict["question"] as? String else { return nil }

        let typeStr = dict["answerType"] as? String ?? "numericInput"
        let answerType = QuestionAnswerType(rawValue: typeStr) ?? .numericInput

        let phaseStr = dict["phase"] as? String ?? "collection"
        let phase = MatchPhase(rawValue: phaseStr) ?? .collection

        return MatchQuestion(
            id: id,
            text: text,
            answerType: answerType,
            phase: phase,
            options: dict["options"] as? [String] ?? [],
            index: dict["index"] as? Int ?? 1,
            total: dict["total"] as? Int ?? 4,
            timeLimit: dict["timeLimit"] as? Int ?? 15,
            correctAnswer: dict["correctAnswer"] as? String,
            correctIndex: dict["correctIndex"] as? Int
        )
    }
}

// MARK: - نتيجة المرحلة 1 (transition)
struct PhaseResult: Decodable, Equatable {
    let phase: String                       // "collection"
    let powers: [String: Int]               // userId → قوة (الـ HP للمرحلة 2)
    let nextPhase: String                   // "battle"

    static func from(_ dict: [String: Any]) -> PhaseResult? {
        guard let phase = dict["phase"] as? String else { return nil }
        return PhaseResult(
            phase: phase,
            powers: dict["powers"] as? [String: Int] ?? [:],
            nextPhase: dict["nextPhase"] as? String ?? "battle"
        )
    }
}

// MARK: - حالة اللاعب
struct MatchPlayer: Equatable {
    let id: String
    let username: String
    let avatarUrl: String?
    let level: Int?
    var hp: Int          // 0..100
    var score: Int

    static func from(_ dict: [String: Any]) -> MatchPlayer? {
        guard let id = dict["id"] as? String,
              let username = dict["username"] as? String else { return nil }
        return MatchPlayer(
            id: id,
            username: username,
            avatarUrl: dict["avatarUrl"] as? String,
            level: dict["level"] as? Int,
            hp: dict["hp"] as? Int ?? 100,
            score: dict["score"] as? Int ?? 0
        )
    }
}

// MARK: - نتيجة إجابة
struct AnswerResult: Equatable {
    let questionId: String
    let userId: String
    let submittedValue: String   // النص اللي أرسله اللاعب (للـ input) أو رقم index كـ String
    let isCorrect: Bool          // (للـ MC أو exact match)
    let isClosest: Bool          // ✨ المرحلة 1: الأقرب
    let isFastest: Bool          // ✨ الأسرع
    let pointsAwarded: Int       // نقاط محصّلة من هذا السؤال
    let newScore: Int?
    let newHP: Int?
    let opponentScore: Int?
    let opponentHP: Int?
    /// (احتياط للقديم)
    let selectedIndex: Int?

    static func from(_ dict: [String: Any]) -> AnswerResult? {
        guard let questionId = dict["questionId"] as? String,
              let userId = dict["userId"] as? String else {
            return nil
        }
        let scores = dict["scores"] as? [String: Int] ?? [:]
        let hps = dict["hp"] as? [String: Int] ?? [:]

        // submittedValue: للنص أو لـ index كـ String
        let value: String = (dict["value"] as? String)
            ?? dict["submittedValue"] as? String
            ?? (dict["selectedIndex"] as? Int).map { String($0) }
            ?? (dict["answerIndex"] as? Int).map { String($0) }
            ?? ""

        return AnswerResult(
            questionId: questionId,
            userId: userId,
            submittedValue: value,
            isCorrect: dict["correct"] as? Bool ?? false,
            isClosest: dict["closest"] as? Bool ?? false,
            isFastest: dict["fastest"] as? Bool ?? false,
            pointsAwarded: dict["pointsAwarded"] as? Int ?? 0,
            newScore: scores[userId] ?? dict["newScore"] as? Int,
            newHP: hps[userId] ?? dict["newHP"] as? Int,
            opponentScore: dict["opponentScore"] as? Int,
            opponentHP: dict["opponentHP"] as? Int,
            selectedIndex: dict["selectedIndex"] as? Int
        )
    }
}

// MARK: - نهاية المباراة
struct MatchEndResult: Equatable {
    let matchId: String
    let didIWin: Bool
    let myScore: Int
    let opponentScore: Int
    let goldReward: Int
    let xpReward: Int
    let opponentName: String?

    static func from(_ dict: [String: Any], myId: String, opponentId: String? = nil) -> MatchEndResult? {
        let matchId = dict["matchId"] as? String ?? ""
        let winnerId = dict["winnerId"] as? String
        let scores = dict["scores"] as? [String: Int] ?? [:]
        let rewards = dict["rewards"] as? [String: Int] ?? [:]
        return MatchEndResult(
            matchId: matchId,
            didIWin: winnerId == myId,
            myScore: scores[myId] ?? 0,
            opponentScore: scores.filter { $0.key != myId }.values.first ?? 0,
            goldReward: rewards["gold"] ?? 0,
            xpReward: rewards["xp"] ?? 0,
            opponentName: dict["opponentName"] as? String
        )
    }
}

// MARK: - سياق المباراة النشطة (لعرض MatchView)
struct ActiveMatchContext: Identifiable, Equatable {
    var id: String { matchId }
    let matchId: String
    /// كل الخصوم (ما عدا المستخدم الحالي) — 1 للـ 1v1، 3 للـ 4player
    let opponents: [MatchPlayer]

    /// توافق قديم — للأكواد اللي تستخدم opponent مفرد
    var opponent: MatchPlayer {
        opponents.first ?? MatchPlayer(id: "opponent", username: "الخصم",
                                        avatarUrl: nil, level: nil, hp: 100, score: 0)
    }
}

// MARK: - استخدام عنصر
struct ItemEffect: Equatable {
    let itemType: String
    let userId: String           // من استخدمه
    let targetId: String?         // الهدف (إن وجد)
    let duration: Int?            // بالثواني (للتجميد)

    static func from(_ dict: [String: Any]) -> ItemEffect? {
        guard let itemType = dict["itemType"] as? String,
              let userId = dict["userId"] as? String else { return nil }
        return ItemEffect(
            itemType: itemType,
            userId: userId,
            targetId: dict["targetId"] as? String,
            duration: dict["duration"] as? Int
        )
    }
}
