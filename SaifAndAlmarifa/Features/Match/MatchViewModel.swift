//
//  MatchViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/MatchViewModel.swift

import Foundation
import Combine

@MainActor
final class MatchViewModel: ObservableObject {

    // MARK: - Inputs
    let matchId: String
    let opponent: MatchPlayer

    // MARK: - Published State
    @Published var currentQuestion: MatchQuestion?
    @Published var selectedAnswerIndex: Int? = nil
    @Published var lastAnswerResult: AnswerResult? = nil
    @Published var isRevealing: Bool = false              // بعد الإجابة، لحظة إظهار النتيجة
    @Published var myHP: Int = 100
    @Published var opponentHP: Int = 100
    @Published var myScore: Int = 0
    @Published var opponentScore: Int = 0
    @Published var timeRemaining: Int = 15
    @Published var attackAnimating: Bool = false          // cannonball في الجو
    @Published var myCastleShaking: Bool = false
    @Published var opponentCastleShaking: Bool = false
    @Published var matchResult: MatchEndResult? = nil
    @Published var inventory: [PowerUpIcon: Int] = [:]    // المخزون
    @Published var activePowerUps: Set<PowerUpIcon> = []  // مفعّل الآن (مؤقتاً)
    @Published var hintMessage: String? = nil             // نص التلميح
    @Published var isFrozen: Bool = false                 // حالة تجميد
    @Published var rematchStatus: RematchStatus = .none   // حالة الإعادة

    enum RematchStatus {
        case none
        case waitingForOpponent   // أنا طلبت — خصمي لم يرد
        case opponentOffered      // خصمي طلب — أنا أرد
        case accepted             // كلانا موافق — match جديد قادم
    }

    // MARK: - Dependencies
    private let socket = AppSocketManager.shared
    private let authManager = AuthManager.shared
    private let toast = ToastManager.shared
    private let storeService = StoreService.shared

    // MARK: - Internal
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var heartbeatStarted = false

    // MARK: - Derived
    var myId: String { authManager.currentUser?.id ?? "" }
    var me: MatchPlayer {
        MatchPlayer(
            id: myId,
            username: authManager.currentUser?.username ?? "أنت",
            avatarUrl: authManager.currentUser?.avatarUrl,
            level: authManager.currentUser?.level,
            hp: myHP,
            score: myScore
        )
    }

    // MARK: - Init
    init(matchId: String, opponent: MatchPlayer) {
        self.matchId = matchId
        self.opponent = opponent
        self.opponentHP = opponent.hp
        self.opponentScore = opponent.score
        bindSocket()
    }

    // MARK: - Lifecycle
    func start() {
        // انضم لـ socket room للـ match
        socket.joinMatch(matchId: matchId)
        GameSoundManager.shared.play(.matchStart)
        Task { await loadInventory() }
    }

    func onDisappear() {
        timer?.invalidate()
        GameSoundManager.shared.stopAll()
    }

    // MARK: - Inventory
    private func loadInventory() async {
        guard let items = try? await storeService.getInventory() else { return }
        var result: [PowerUpIcon: Int] = [:]
        for item in items {
            if let match = PowerUpIcon.allCases.first(where: { $0.storeType == item.itemType }) {
                result[match, default: 0] += item.quantity
            }
        }
        inventory = result
    }

    // MARK: - Socket
    private func bindSocket() {
        // سؤال جديد
        socket.onMatchQuestion
            .sink { [weak self] data in
                self?.handleIncomingQuestion(data)
            }
            .store(in: &cancellables)

        // تم إرسال إجابة
        socket.onMatchAnswerSubmitted
            .sink { [weak self] data in
                self?.handleAnswerSubmitted(data)
            }
            .store(in: &cancellables)

        // هجوم
        socket.onMatchAttack
            .sink { [weak self] data in
                self?.handleAttack(data)
            }
            .store(in: &cancellables)

        // عنصر مُستخدم
        socket.onMatchItemUsed
            .sink { [weak self] data in
                self?.handleItemUsed(data)
            }
            .store(in: &cancellables)

        // تأثير عنصر
        socket.onMatchItemEffect
            .sink { [weak self] data in
                self?.handleItemEffect(data)
            }
            .store(in: &cancellables)

        // نهاية المباراة
        socket.onMatchEnded
            .sink { [weak self] data in
                self?.handleMatchEnded(data)
            }
            .store(in: &cancellables)

        // طلب إعادة من الخصم
        socket.onRematchRequested
            .sink { [weak self] data in
                guard let self,
                      (data["matchId"] as? String) == self.matchId,
                      (data["fromUserId"] as? String) != self.myId else { return }

                if self.rematchStatus == .waitingForOpponent {
                    // كلانا طلب — سيرسل السيرفر match:rematch-accepted
                } else {
                    self.rematchStatus = .opponentOffered
                    self.toast.info("\(self.opponent.username) يريد إعادة التحدي")
                    HapticManager.success()
                }
            }
            .store(in: &cancellables)

        // Rematch مقبول → match جديد
        socket.onRematchAccepted
            .sink { [weak self] data in
                guard let self else { return }
                self.rematchStatus = .accepted
                if let newMatchId = data["newMatchId"] as? String ?? data["matchId"] as? String {
                    self.toast.success("بدء المباراة الجديدة!")
                    GameSoundManager.shared.play(.matchStart)
                    // سينتقل التطبيق لمباراة جديدة عبر MainViewModel.onMatchFound
                    self.socket.joinMatch(matchId: newMatchId)
                }
            }
            .store(in: &cancellables)
    }

    /// طلب إعادة تحدّي
    func requestRematch() {
        socket.requestRematch(matchId: matchId)
        rematchStatus = .waitingForOpponent
        HapticManager.medium()
        toast.info("تم إرسال طلب الإعادة")
    }

    // MARK: - Handlers

    private func handleIncomingQuestion(_ data: [String: Any]) {
        guard matchIdMatches(data),
              let q = MatchQuestion.from(data) else { return }
        currentQuestion = q
        selectedAnswerIndex = nil
        lastAnswerResult = nil
        isRevealing = false
        hintMessage = nil
        timeRemaining = q.timeLimit
        startTimer()
        GameSoundManager.shared.play(.questionAppear)
    }

    private func handleAnswerSubmitted(_ data: [String: Any]) {
        guard matchIdMatches(data),
              let result = AnswerResult.from(data) else { return }

        // تحديث النقاط/HP
        if let s = result.newScore, result.userId == myId { myScore = s }
        if let h = result.newHP, result.userId == myId { myHP = h }
        if result.userId != myId {
            if let s = result.opponentScore ?? result.newScore { opponentScore = s }
            if let h = result.opponentHP ?? result.newHP { opponentHP = h }
        }

        // إذا الإجابة لي
        if result.userId == myId {
            lastAnswerResult = result
            isRevealing = true
            if var q = currentQuestion {
                // علّم الإجابة الصحيحة إذا رجعها السيرفر
                if let correct = (data["correctIndex"] as? Int) {
                    q.correctIndex = correct
                    currentQuestion = q
                }
            }

            if result.isCorrect {
                fireAttackOnOpponent()
                GameSoundManager.shared.play(.answerCorrect)
                HapticManager.success()
            } else {
                GameSoundManager.shared.play(.answerWrong)
                HapticManager.error()
            }
        }
    }

    private func handleAttack(_ data: [String: Any]) {
        guard matchIdMatches(data) else { return }
        let attackerId = data["attackerId"] as? String
        let damage = data["damage"] as? Int ?? 10

        if attackerId == myId {
            // أنا الذي هاجمت — (الأنيميشن من fireAttackOnOpponent)
            opponentHP = max(0, opponentHP - damage)
        } else {
            // تعرّضت لهجوم
            myCastleShaking = true
            myHP = max(0, myHP - damage)
            GameSoundManager.shared.play(.castleHit)
            HapticManager.heavy()
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                await MainActor.run { self.myCastleShaking = false }
            }
        }
    }

    private func handleItemUsed(_ data: [String: Any]) {
        guard matchIdMatches(data),
              let effect = ItemEffect.from(data) else { return }

        if let powerUp = PowerUpIcon.allCases.first(where: { $0.storeType == effect.itemType }) {
            if effect.userId == myId {
                GameSoundManager.shared.playPowerUp(powerUp)
            } else {
                // خصمي استخدم عنصر ضدّي
                let msg = "\(opponent.username) استخدم \(powerUp.titleAr)"
                toast.info(msg)
            }
        }
    }

    private func handleItemEffect(_ data: [String: Any]) {
        guard matchIdMatches(data) else { return }

        // hint
        if let hint = data["hint"] as? String {
            hintMessage = hint
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await MainActor.run { self.hintMessage = nil }
            }
        }

        // 50/50 — disable indices
        if let disabled = data["disabledIndices"] as? [Int], var q = currentQuestion {
            q.disabledIndices = Set(disabled)
            currentQuestion = q
        }

        // freeze
        if let frozen = data["frozen"] as? Bool, frozen {
            isFrozen = true
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run { self.isFrozen = false }
            }
        }
    }

    private func handleMatchEnded(_ data: [String: Any]) {
        guard matchIdMatches(data) else { return }
        timer?.invalidate()
        GameSoundManager.shared.stop(.heartbeat)

        if let result = MatchEndResult.from(data, myId: myId) {
            matchResult = result
            GameSoundManager.shared.play(result.didIWin ? .matchVictory : .matchDefeat)
            if !result.didIWin {
                GameSoundManager.shared.play(.castleCollapse, volumeOverride: 0.6)
            }
            HapticManager.heavy()
        }
    }

    private func matchIdMatches(_ data: [String: Any]) -> Bool {
        guard let id = data["matchId"] as? String else { return true }
        return id == matchId
    }

    // MARK: - Actions

    /// اختيار إجابة
    func selectAnswer(_ index: Int) {
        guard let q = currentQuestion, selectedAnswerIndex == nil, !isRevealing else { return }
        guard !q.disabledIndices.contains(index) else { return }

        selectedAnswerIndex = index
        GameSoundManager.shared.play(.answerTap)
        HapticManager.medium()
        timer?.invalidate()

        socket.submitAnswer(
            matchId: matchId,
            questionId: q.id,
            answer: String(index)
        )
    }

    /// استخدام عنصر
    func usePowerUp(_ powerUp: PowerUpIcon) {
        guard (inventory[powerUp] ?? 0) > 0 else {
            toast.warning("لا تملك \(powerUp.titleAr)")
            return
        }
        // نقص الكمية محلياً (optimistic)
        inventory[powerUp] = max(0, (inventory[powerUp] ?? 0) - 1)

        socket.useItem(matchId: matchId, itemId: powerUp.storeType)
        GameSoundManager.shared.playPowerUp(powerUp)
        HapticManager.medium()
    }

    // MARK: - Attack Animation (بصرياً)
    private func fireAttackOnOpponent() {
        Task { @MainActor in
            attackAnimating = true
            GameSoundManager.shared.play(.cannonFire)
            try? await Task.sleep(nanoseconds: 700_000_000)
            attackAnimating = false
            opponentCastleShaking = true
            GameSoundManager.shared.play(.castleHit, volumeOverride: 0.7)
            HapticManager.heavy()
            try? await Task.sleep(nanoseconds: 600_000_000)
            opponentCastleShaking = false
        }
    }

    // MARK: - Timer
    private func startTimer() {
        timer?.invalidate()
        heartbeatStarted = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self else { t.invalidate(); return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    // heartbeat على آخر 5 ثوانٍ
                    if self.timeRemaining == 5 && !self.heartbeatStarted {
                        self.heartbeatStarted = true
                        GameSoundManager.shared.play(.heartbeat, loop: true, volumeOverride: 0.5)
                    }
                } else {
                    t.invalidate()
                    GameSoundManager.shared.stop(.heartbeat)
                    self.timeUp()
                }
            }
        }
    }

    private func timeUp() {
        guard let q = currentQuestion, selectedAnswerIndex == nil, !isRevealing else { return }
        // عدم اختيار إجابة — أرسل -1
        selectedAnswerIndex = -1
        socket.submitAnswer(matchId: matchId, questionId: q.id, answer: "-1")
        GameSoundManager.shared.play(.answerWrong)
        HapticManager.warning()
    }
}
