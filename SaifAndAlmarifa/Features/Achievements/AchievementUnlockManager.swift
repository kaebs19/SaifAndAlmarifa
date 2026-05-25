//
//  AchievementUnlockManager.swift
//  SaifAndAlmarifa
//
//  يستمع لـ achievement:unlocked socket event ويعرض banner احتفال
//

import Foundation
import Combine

@MainActor
final class AchievementUnlockManager: ObservableObject {

    static let shared = AchievementUnlockManager()

    @Published var pending: [AchievementUnlock] = []
    @Published var currentlyShowing: AchievementUnlock?

    private var cancellables = Set<AnyCancellable>()

    private init() { bind() }

    private func bind() {
        AppSocketManager.shared.onAchievementUnlocked
            .sink { [weak self] data in
                guard let self,
                      let unlock = AchievementUnlock.from(data) else { return }
                self.enqueue(unlock)
            }
            .store(in: &cancellables)
    }

    /// عرض إنجاز جديد (يُسجَّل في القائمة لو هناك واحد ظاهر الآن)
    func enqueue(_ unlock: AchievementUnlock) {
        if currentlyShowing == nil {
            currentlyShowing = unlock
            HapticManager.success()
            GameSoundManager.shared.play(.matchVictory, volumeOverride: 0.6)
            scheduleAutoDismiss()
        } else {
            pending.append(unlock)
        }
    }

    /// إغلاق يدوي
    func dismissCurrent() {
        currentlyShowing = nil
        if !pending.isEmpty {
            // التالي بعد لحظة بسيطة
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 400_000_000)
                let next = pending.removeFirst()
                currentlyShowing = next
                HapticManager.success()
                scheduleAutoDismiss()
            }
        }
    }

    private func scheduleAutoDismiss() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            guard let self else { return }
            // فقط لو نفس الإنجاز ما زال ظاهر (المستخدم ما أقفله يدوياً)
            if self.currentlyShowing != nil {
                self.dismissCurrent()
            }
        }
    }
}
