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
    /// قائمة الخصوم (1 للـ 1v1، 3 للـ 4p)
    let initialOpponents: [MatchPlayer]

    // MARK: - Published State
    @Published var currentQuestion: MatchQuestion?
    @Published var selectedAnswerIndex: Int? = nil
    @Published var lastAnswerResult: AnswerResult? = nil
    @Published var isRevealing: Bool = false              // بعد الإجابة، لحظة إظهار النتيجة
    @Published var myHP: Int = 100
    @Published var myScore: Int = 0
    @Published var opponents: [MatchPlayer] = []          // حالة الخصوم المتطوّرة
    @Published var eliminatedIds: Set<String> = []        // اللاعبون الخارجون
    @Published var timeRemaining: Int = 15
    @Published var attackAnimating: Bool = false          // cannonball في الجو
    @Published var attackTargetId: String? = nil          // الهدف للأنيميشن
    @Published var myCastleShaking: Bool = false
    @Published var shakingOpponentId: String? = nil       // أي قلعة تهتز الآن
    @Published var matchResult: MatchEndResult? = nil
    @Published var inventory: [PowerUpIcon: Int] = [:]    // المخزون
    @Published var activePowerUps: Set<PowerUpIcon> = []  // مفعّل الآن (مؤقتاً)
    @Published var hintMessage: String? = nil             // نص التلميح
    @Published var isFrozen: Bool = false                 // حالة تجميد
    @Published var rematchStatus: RematchStatus = .none   // حالة الإعادة
    @Published var preMatchCountdown: Int? = nil          // 3, 2, 1 قبل أول سؤال

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
    private var questionStartTime: Date?

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
    init(matchId: String, opponents: [MatchPlayer]) {
        self.matchId = matchId
        self.initialOpponents = opponents
        self.opponents = opponents
        bindSocket()
    }

    /// كم هي مباراة 1 ضد 1؟ (مفيد للـ layout)
    var isOneVsOne: Bool { initialOpponents.count == 1 }

    /// اسم الخصم الأول (للـ UI في 1v1)
    var opponent: MatchPlayer { opponents.first ?? initialOpponents.first ?? MatchPlayer(id: "?", username: "?", avatarUrl: nil, level: nil, hp: 0, score: 0) }

    // MARK: - Lifecycle
    func start() {
        // انضم لـ socket room للـ match
        socket.joinMatch(matchId: matchId)
        GameSoundManager.shared.play(.matchStart)
        Task { await loadInventory() }
        startPreMatchCountdown()
    }

    /// 3-2-1 قبل أول سؤال
    private func startPreMatchCountdown() {
        preMatchCountdown = 3
        Task { @MainActor in
            for i in (1...3).reversed() {
                preMatchCountdown = i
                GameSoundManager.shared.play(.answerTap)
                HapticManager.light()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            preMatchCountdown = nil
        }
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
        // بداية المباراة
        socket.onMatchStarted
            .sink { [weak self] matchId in
                guard let self, matchId == self.matchId else { return }
                // أوقف countdown لو ما انتهى
                if self.preMatchCountdown != nil {
                    self.preMatchCountdown = nil
                }
            }
            .store(in: &cancellables)

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

        // خروج لاعب
        socket.onMatchEliminated
            .sink { [weak self] data in
                self?.handleEliminated(data)
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
        questionStartTime = Date()   // ← بداية العد للـ timeMs
        startTimer()
        GameSoundManager.shared.play(.questionAppear)
    }

    private func handleAnswerSubmitted(_ data: [String: Any]) {
        guard matchIdMatches(data),
              let result = AnswerResult.from(data) else { return }

        // تحديث النقاط/HP
        if result.userId == myId {
            if let s = result.newScore { myScore = s }
            if let h = result.newHP { myHP = h }
        } else {
            // حدّث الخصم الموافق
            if let idx = opponents.firstIndex(where: { $0.id == result.userId }) {
                var p = opponents[idx]
                if let s = result.newScore ?? result.opponentScore { p.score = s }
                if let h = result.newHP ?? result.opponentHP { p.hp = h }
                opponents[idx] = p
            }
        }

        // إذا الإجابة لي
        if result.userId == myId {
            lastAnswerResult = result
            isRevealing = true
            if var q = currentQuestion {
                if let correct = (data["correctIndex"] as? Int) {
                    q.correctIndex = correct
                    currentQuestion = q
                }
            }

            if result.isCorrect {
                // في 1v1 اهجم على الوحيد، في 4p السيرفر يقرر الهدف
                let targetId = data["attackTargetId"] as? String ?? opponents.first?.id
                fireAttackOnOpponent(targetId: targetId)
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
        let targetId = data["targetId"] as? String
        let damage = data["damage"] as? Int ?? 10
        // السيرفر يرسل HP الجديد مباشرة
        let serverTargetHp = data["targetHp"] as? Int

        if targetId == myId {
            // تعرّضت لهجوم
            myCastleShaking = true
            myHP = serverTargetHp ?? max(0, myHP - damage)
            GameSoundManager.shared.play(.castleHit)
            HapticManager.heavy()
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                await MainActor.run { self.myCastleShaking = false }
            }
        } else if let tid = targetId,
                  let idx = opponents.firstIndex(where: { $0.id == tid }) {
            // هجوم على أحد الخصوم (مني أو من لاعب آخر)
            var p = opponents[idx]
            p.hp = serverTargetHp ?? max(0, p.hp - damage)
            opponents[idx] = p
            shakingOpponentId = tid
            GameSoundManager.shared.play(.castleHit, volumeOverride: 0.7)
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                await MainActor.run { self.shakingOpponentId = nil }
            }
        }

        _ = attackerId
    }

    /// لاعب خرج من المباراة (HP = 0)
    private func handleEliminated(_ data: [String: Any]) {
        guard matchIdMatches(data),
              let userId = data["userId"] as? String else { return }
        eliminatedIds.insert(userId)
        if userId == myId {
            toast.error("خرجت من المباراة")
            HapticManager.warning()
        } else if let name = opponents.first(where: { $0.id == userId })?.username {
            toast.info("\(name) خرج من المباراة")
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

        // احسب زمن الإجابة بالميلي ثانية
        let elapsedMs = Int((Date().timeIntervalSince(questionStartTime ?? Date())) * 1000)

        socket.submitAnswer(
            matchId: matchId,
            answer: String(index),
            timeMs: elapsedMs
        )
        _ = q  // silence warning
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

        // فعّل الـ power-up بصرياً لبعض الوقت
        activatePowerUpVisual(powerUp)
    }

    /// تفعيل تأثير بصري للـ power-up
    private func activatePowerUpVisual(_ powerUp: PowerUpIcon) {
        activePowerUps.insert(powerUp)
        let duration: UInt64 = powerUp == .shield ? 10_000_000_000 : 3_000_000_000
        Task {
            try? await Task.sleep(nanoseconds: duration)
            await MainActor.run { self.activePowerUps.remove(powerUp) }
        }
    }

    // MARK: - Attack Animation (بصرياً)
    private func fireAttackOnOpponent(targetId: String? = nil) {
        Task { @MainActor in
            attackTargetId = targetId ?? opponents.first?.id
            attackAnimating = true
            GameSoundManager.shared.play(.cannonFire)
            try? await Task.sleep(nanoseconds: 700_000_000)
            attackAnimating = false
            shakingOpponentId = attackTargetId
            GameSoundManager.shared.play(.castleHit, volumeOverride: 0.7)
            HapticManager.heavy()
            try? await Task.sleep(nanoseconds: 600_000_000)
            shakingOpponentId = nil
            attackTargetId = nil
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
        // عدم اختيار إجابة — أرسل -1 مع الوقت الكامل
        selectedAnswerIndex = -1
        let elapsedMs = Int((Date().timeIntervalSince(questionStartTime ?? Date())) * 1000)
        socket.submitAnswer(matchId: matchId, answer: "-1", timeMs: elapsedMs)
        GameSoundManager.shared.play(.answerWrong)
        HapticManager.warning()
        _ = q
    }
}
