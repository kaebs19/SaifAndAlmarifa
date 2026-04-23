//
//  MatchModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Models/MatchModels.swift
//  نماذج بيانات المباراة

import Foundation

// MARK: - سؤال في المباراة
struct MatchQuestion: Identifiable, Equatable {
    let id: String
    let text: String
    let options: [String]        // 4 خيارات عادة
    let index: Int               // 1..total
    let total: Int               // مثلاً 10
    let timeLimit: Int           // بالثواني
    var correctIndex: Int?       // يُعلن بعد الإرسال
    var disabledIndices: Set<Int> = []  // للـ 50/50

    static func from(_ dict: [String: Any]) -> MatchQuestion? {
        guard let id = dict["questionId"] as? String ?? dict["id"] as? String,
              let text = dict["text"] as? String ?? dict["question"] as? String,
              let options = dict["options"] as? [String] else { return nil }
        return MatchQuestion(
            id: id,
            text: text,
            options: options,
            index: dict["index"] as? Int ?? 1,
            total: dict["total"] as? Int ?? 10,
            timeLimit: dict["timeLimit"] as? Int ?? 15,
            correctIndex: dict["correctIndex"] as? Int
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
    let selectedIndex: Int
    let isCorrect: Bool
    let newScore: Int?
    let newHP: Int?
    let opponentScore: Int?
    let opponentHP: Int?

    static func from(_ dict: [String: Any]) -> AnswerResult? {
        guard let questionId = dict["questionId"] as? String,
              let userId = dict["userId"] as? String,
              let idx = dict["selectedIndex"] as? Int ?? dict["answerIndex"] as? Int else {
            return nil
        }
        let scores = dict["scores"] as? [String: Int] ?? [:]
        let hps = dict["hp"] as? [String: Int] ?? [:]
        return AnswerResult(
            questionId: questionId,
            userId: userId,
            selectedIndex: idx,
            isCorrect: dict["correct"] as? Bool ?? false,
            newScore: scores[userId] ?? dict["newScore"] as? Int,
            newHP: hps[userId] ?? dict["newHP"] as? Int,
            opponentScore: dict["opponentScore"] as? Int,
            opponentHP: dict["opponentHP"] as? Int
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
    let opponent: MatchPlayer
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
