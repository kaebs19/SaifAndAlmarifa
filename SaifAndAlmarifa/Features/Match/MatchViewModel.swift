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
    @Published var inputAnswer: String = ""               // ✨ للـ input
    @Published var hasSubmitted: Bool = false             // تم إرسال إجابتي
    @Published var currentPhase: MatchPhase = .collection // ✨ المرحلة الحالية
    @Published var phaseResult: PhaseResult? = nil        // ✨ نتيجة المرحلة 1
    @Published var showPhaseTransition: Bool = false      // عرض شاشة الانتقال
    @Published var lastAnswerResult: AnswerResult? = nil
    @Published var isRevealing: Bool = false              // بعد الإجابة، لحظة إظهار النتيجة
    @Published var myHP: Int = 0
    @Published var myMaxHP: Int = 0       // ✨ القوة المتراكمة من المرحلة 1
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
    @Published var rangeHint: (min: Int, max: Int)? = nil // ✨ تلميح مدى رقمي (العصفور)

    // MARK: - Stage 1: Game Feel
    @Published var answeredUserIds: Set<String> = []      // مَن جاوب على السؤال الحالي
    @Published var streak: Int = 0                        // إجابات صحيحة متتالية
    @Published var showCombo: Bool = false                // banner combo
    @Published var wrongShakeNonce: Int = 0               // trigger لاهتزاز الإجابة الخاطئة
    @Published var pointsBurstNonce: Int = 0              // trigger للاحتفال بالنقاط
    @Published var questionHistory: [QuestionStat] = []   // ✨ سجل أداء كل سؤال
    private var wasCriticalHP: Bool = false               // لمنع تكرار haptic critical
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
    private var lastQuestionArrivedAt: Date?
    private var questionsTooFastCount: Int = 0

    // MARK: - Derived
    var myId: String { authManager.currentUser?.id ?? "" }
    var me: MatchPlayer {
        MatchPlayer(
            id: myId,
            username: authManager.currentUser?.username ?? "أنت",
            avatarUrl: authManager.currentUser?.avatarUrl,
            level: authManager.currentUser?.level,
            hp: myHP,
            maxHp: myMaxHP,
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

    /// HP حرج (≤25%) في battle phase
    var isCriticalHP: Bool {
        guard currentPhase == .battle, myMaxHP > 0, myHP > 0 else { return false }
        return Double(myHP) / Double(myMaxHP) <= 0.25
    }

    /// اسم الخصم الأول (للـ UI في 1v1)
    var opponent: MatchPlayer { opponents.first ?? initialOpponents.first ?? MatchPlayer(id: "?", username: "?", avatarUrl: nil, level: nil, hp: 0, maxHp: 0, score: 0) }

    // MARK: - Lifecycle
    func start() {
        // انضم لـ socket room للـ match
        socket.joinMatch(matchId: matchId)
        GameSoundManager.shared.play(.matchStart)
        Task { await loadInventory() }
        startPreMatchCountdown()
    }

    /// 3-2-1 قبل أول سؤال — backend يعطي 2s قبل match:question[1]
    private func startPreMatchCountdown() {
        Task { @MainActor in
            for i in (1...3).reversed() {
                guard currentQuestion == nil else {
                    preMatchCountdown = nil
                    return
                }
                preMatchCountdown = i
                GameSoundManager.shared.play(.answerTap)
                HapticManager.light()
                try? await Task.sleep(nanoseconds: 700_000_000)
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

        // تغيّر مرحلة
        socket.onMatchPhase
            .sink { [weak self] data in
                guard let self, self.matchIdMatches(data) else { return }
                if let str = data["phase"] as? String,
                   let phase = MatchPhase(rawValue: str) {
                    self.currentPhase = phase
                    if phase == .battle {
                        // أخفِ شاشة الـ transition بعد لحظات
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            self.showPhaseTransition = false
                        }
                    }
                }
            }
            .store(in: &cancellables)

        // نتائج المرحلة 1
        socket.onMatchPhaseResult
            .sink { [weak self] data in
                guard let self, self.matchIdMatches(data),
                      let result = PhaseResult.from(data) else { return }
                self.phaseResult = result
                self.currentPhase = .transition
                self.showPhaseTransition = true

                // ✨ ابدأ Phase 2 بـ streak جديد
                self.streak = 0
                self.showCombo = false

                // طبّق power على HP — قلعتي + الخصوم (يحفظ maxHp للنسبة)
                if let myPower = result.powers[self.myId] {
                    self.myHP = myPower
                    self.myMaxHP = myPower
                }
                for (idx, opp) in self.opponents.enumerated() {
                    if let p = result.powers[opp.id] {
                        var updated = opp
                        updated.hp = p
                        updated.maxHp = p
                        self.opponents[idx] = updated
                    }
                }

                GameSoundManager.shared.play(.matchStart, volumeOverride: 0.5)
                HapticManager.success()
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

        // ألغِ الـ countdown إذا أول سؤال وصل قبل ما يخلص
        if preMatchCountdown != nil {
            preMatchCountdown = nil
        }

        // كشف الأسئلة المتسارعة (Backend timing issue)
        let now = Date()
        if let last = lastQuestionArrivedAt {
            let gap = now.timeIntervalSince(last)
            if gap < 2.0 {
                questionsTooFastCount += 1
                #if DEBUG
                print("⚠️ [Match] Question arrived too fast — gap=\(String(format: "%.2f", gap))s (count=\(questionsTooFastCount))")
                #endif
                // عرّف المستخدم بالمشكلة بعد 3 حالات
                if questionsTooFastCount == 3 {
                    toast.warning("⚠️ الأسئلة تمر بسرعة")
                }
            }
        }
        lastQuestionArrivedAt = now

        currentQuestion = q
        currentPhase = q.phase
        selectedAnswerIndex = nil
        inputAnswer = ""
        hasSubmitted = false
        lastAnswerResult = nil
        isRevealing = false
        showPhaseTransition = false
        hintMessage = nil
        rangeHint = nil
        answeredUserIds.removeAll()                  // ✨ سؤال جديد → ينتظر الكل
        showCombo = false                            // أخفِ combo banner
        timeRemaining = q.timeLimit
        questionStartTime = Date()
        startTimer()
        GameSoundManager.shared.play(.questionAppear)

        // 🎯 سؤال حاسم — تنبيه قوي
        if q.isTiebreaker {
            HapticManager.warning()
            toast.warning("🎯 سؤال حاسم!")
        }
    }

    private func handleAnswerSubmitted(_ data: [String: Any]) {
        guard matchIdMatches(data),
              let result = AnswerResult.from(data) else { return }

        // ✨ سجّل من جاوب (لـ "الخصم جاوب" indicator)
        answeredUserIds.insert(result.userId)

        // HP لا يُحدَّث إلا في المرحلة 2 (battle) — حماية من backend بيرسلها بالغلط
        let allowHpUpdate = currentPhase == .battle

        // تحديث النقاط/HP
        if result.userId == myId {
            if let s = result.newScore { myScore = s }
            if allowHpUpdate, let h = result.newHP { myHP = h }
        } else {
            // حدّث الخصم الموافق
            if let idx = opponents.firstIndex(where: { $0.id == result.userId }) {
                var p = opponents[idx]
                if let s = result.newScore ?? result.opponentScore { p.score = s }
                if allowHpUpdate, let h = result.newHP ?? result.opponentHP { p.hp = h }
                opponents[idx] = p
            }
        }

        // إذا الإجابة لي
        if result.userId == myId {
            lastAnswerResult = result
            isRevealing = true
            if var q = currentQuestion {
                if let correctIdx = data["correctIndex"] as? Int {
                    q.correctIndex = correctIdx
                }
                // ✨ التقط correctAnswer للأسئلة input (numeric/text)
                if let correctStr = data["correctAnswer"] as? String {
                    q.correctAnswer = correctStr
                }
                currentQuestion = q
            }

            if result.isCorrect {
                // في 1v1 اهجم على الوحيد، في 4p السيرفر يقرر الهدف
                let targetId = data["attackTargetId"] as? String ?? opponents.first?.id
                fireAttackOnOpponent(targetId: targetId)
                GameSoundManager.shared.play(.answerCorrect)
                HapticManager.success()
                // ✨ Streak + Combo
                streak += 1
                if streak >= 2 {
                    showCombo = true
                    HapticManager.comboTick(count: streak)   // تكّات متتابعة
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        self.showCombo = false
                    }
                }
            } else {
                GameSoundManager.shared.play(.answerWrong)
                HapticManager.error()
                streak = 0   // ✨ كسر السلسلة
                wrongShakeNonce += 1   // ✨ trigger الاهتزاز
            }

            // ✨ احتفال بالنقاط (للـ correct + closest)
            if result.pointsAwarded > 0 {
                pointsBurstNonce += 1
            }

            // ✨ سجّل في الـ history للـ summary chart
            if let q = currentQuestion {
                questionHistory.append(QuestionStat(
                    index: q.index,
                    phase: q.phase,
                    isCorrect: result.isCorrect,
                    isClosest: result.isClosest,
                    isFastest: result.isFastest,
                    pointsAwarded: result.pointsAwarded,
                    timeMs: result.timeMs
                ))
            }
        }
    }

    /// ✨ كشف دخول حالة HP حرجة (يستدعى بعد كل تحديث HP)
    private func checkCriticalHPTransition() {
        let nowCritical = isCriticalHP
        if nowCritical && !wasCriticalHP {
            // أول مرة دخلت critical
            HapticManager.warning()
            GameSoundManager.shared.play(.heartbeat, loop: true, volumeOverride: 0.7)
        } else if !nowCritical && wasCriticalHP {
            // خرجت من critical (مثلاً ربح أو HP زاد)
            GameSoundManager.shared.stop(.heartbeat)
        }
        wasCriticalHP = nowCritical
    }

    private func handleAttack(_ data: [String: Any]) {
        guard matchIdMatches(data) else { return }
        // الهجوم فقط في مرحلة المعركة
        guard currentPhase == .battle else { return }
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
            checkCriticalHPTransition()
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
        // الإقصاء فقط في مرحلة المعركة
        guard currentPhase == .battle else { return }
        eliminatedIds.insert(userId)
        if userId == myId {
            toast.error("خرجت من المباراة")
            HapticManager.criticalHit()                    // ✨ ضربة قاضية درامية
            GameSoundManager.shared.play(.castleCollapse, volumeOverride: 0.9)
        } else if let name = opponents.first(where: { $0.id == userId })?.username {
            toast.info("\(name) خرج من المباراة")
            HapticManager.success()                        // ✨ خصم خرج = نجاح
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

        // 🐦 العصفور: مدى رقمي { rangeHint: { min, max } }
        if let range = data["rangeHint"] as? [String: Any],
           let lo = range["min"] as? Int,
           let hi = range["max"] as? Int {
            rangeHint = (min: lo, max: hi)
            GameSoundManager.shared.playPowerUp(.bird)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                self.rangeHint = nil
            }
        }

        // 👁 كشف الإجابة (MCQ) — يضع correctIndex على السؤال
        if let correct = data["correctIndex"] as? Int,
           data["itemType"] as? String == "reveal_answer",
           var q = currentQuestion {
            q.correctIndex = correct
            currentQuestion = q
            GameSoundManager.shared.playPowerUp(.revealAnswer)
            HapticManager.success()
        }

        // 👁 كشف رقم (numericInput) — backend يرسل revealedDigit + position
        if let digit = data["revealedDigit"] as? String,
           data["itemType"] as? String == "reveal_answer" {
            let pos = data["position"] as? Int ?? 0
            hintMessage = "👁 الرقم في المنزلة \(pos + 1): \(digit)"
            GameSoundManager.shared.playPowerUp(.revealAnswer)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                self.hintMessage = nil
            }
        }

        // 💡 hint بنسب على MCQ — { optionWeights: { "0": 70, "1": 10, ... } }
        if let weights = data["optionWeights"] as? [String: Int] {
            let lines = weights
                .compactMap { kv -> (Int, Int)? in
                    guard let idx = Int(kv.key) else { return nil }
                    return (idx, kv.value)
                }
                .sorted { $0.1 > $1.1 }
                .prefix(2)
                .map { "\(["A","B","C","D"][$0.0]): \($0.1)%" }
                .joined(separator: " · ")
            hintMessage = "💡 \(lines)"
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                self.hintMessage = nil
            }
        }
    }

    private func handleMatchEnded(_ data: [String: Any]) {
        guard matchIdMatches(data) else { return }
        timer?.invalidate()
        GameSoundManager.shared.stop(.heartbeat)
        wasCriticalHP = false

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

    /// إرسال إجابة (نص أو index) — موحّد
    func submitAnswer() {
        guard !hasSubmitted, !isRevealing else { return }
        guard currentQuestion != nil else { return }

        let trimmed = inputAnswer.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        hasSubmitted = true
        GameSoundManager.shared.play(.answerTap)
        HapticManager.medium()
        // ما نوقف الـ timer — الخصم قد يجاوب أيضاً، السيرفر يقفل لما الكل يجاوب

        let elapsedMs = Int((Date().timeIntervalSince(questionStartTime ?? Date())) * 1000)
        socket.submitAnswer(matchId: matchId, answer: trimmed, timeMs: elapsedMs)
    }

    /// (احتياط للـ MC القديم)
    func selectAnswer(_ index: Int) {
        guard let q = currentQuestion, !hasSubmitted, !isRevealing else { return }
        guard !q.disabledIndices.contains(index) else { return }
        selectedAnswerIndex = index
        inputAnswer = String(index)
        submitAnswer()
        _ = q
    }

    /// استخدام عنصر
    func usePowerUp(_ powerUp: PowerUpIcon) {
        guard (inventory[powerUp] ?? 0) > 0 else {
            toast.warning("لا تملك \(powerUp.titleAr)")
            return
        }
        // لا تستخدم بعد الإجابة أو خلال الكشف
        guard !hasSubmitted, !isRevealing else {
            toast.warning("استخدمه قبل الإجابة")
            return
        }

        // نقص الكمية محلياً (optimistic)
        inventory[powerUp] = max(0, (inventory[powerUp] ?? 0) - 1)

        socket.useItem(matchId: matchId, itemId: powerUp.storeType)
        GameSoundManager.shared.playPowerUp(powerUp)
        HapticManager.medium()

        // فعّل الـ power-up بصرياً لبعض الوقت
        activatePowerUpVisual(powerUp)

        // تأثير محلي فوري (بدون انتظار backend)
        applyLocalEffect(powerUp)
    }

    /// تطبيق تأثير محلي للـ power-up (يعمل بدون backend)
    private func applyLocalEffect(_ powerUp: PowerUpIcon) {
        switch powerUp {
        case .freeze:
            // ✨ Backend يجمّد الخصم 5 ثوانٍ (يستقبل match:item-effect على جهازه)
            toast.info("❄️ تم تجميد الخصم")

        case .skip:
            // إنهاء السؤال الحالي بإجابة فارغة (ينتظر السؤال التالي)
            if !hasSubmitted {
                hasSubmitted = true
                let elapsedMs = Int((Date().timeIntervalSince(questionStartTime ?? Date())) * 1000)
                socket.submitAnswer(matchId: matchId, answer: "", timeMs: elapsedMs)
                toast.info("⏭ تم تخطّي السؤال")
            }

        case .hint:
            // تلميح محلي بسيط (لا يكشف الإجابة الكاملة)
            if let q = currentQuestion {
                if q.answerType == .multipleChoice && !q.options.isEmpty {
                    hintMessage = "💡 الإجابة من بين \(q.options.count) خيارات"
                } else {
                    hintMessage = "💡 خذ نفساً عميقاً وفكّر"
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    self.hintMessage = nil
                }
            }

        case .fiftyFifty:
            // لا يعمل محلياً (نحتاج correctIndex من backend)
            if let q = currentQuestion, q.answerType == .multipleChoice {
                toast.info("🎯 50/50 — في انتظار backend")
            } else {
                toast.warning("غير متاح لهذا السؤال")
            }

        case .bird:
            // العصفور: يضيّق المدى الرقمي — يحتاج backend ليرسل rangeHint
            if let q = currentQuestion, q.answerType == .numericInput {
                toast.info("🐦 العصفور يبحث...")
            } else {
                toast.warning("العصفور للأسئلة الرقمية فقط")
            }

        case .revealAnswer:
            // الكشف: للـ MCQ يكشف الصحيح، للـ numericInput يكشف رقماً
            if currentQuestion?.answerType == .multipleChoice {
                toast.info("👁 يتمّ الكشف...")
            } else if currentQuestion?.answerType == .numericInput {
                toast.info("👁 يتمّ كشف رقم...")
            }

        case .shield, .thunder, .double, .revive:
            // visual فقط — تأثيرها يطبّق عبر backend
            break
        }
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
        guard !hasSubmitted, !isRevealing else { return }
        hasSubmitted = true
        let elapsedMs = Int((Date().timeIntervalSince(questionStartTime ?? Date())) * 1000)
        // إرسال إجابة فارغة عند انتهاء الوقت
        socket.submitAnswer(matchId: matchId, answer: "", timeMs: elapsedMs)
        GameSoundManager.shared.play(.answerWrong)
        HapticManager.warning()
    }
}
