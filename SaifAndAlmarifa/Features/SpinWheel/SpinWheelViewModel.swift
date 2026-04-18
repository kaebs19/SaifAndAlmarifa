//
//  SpinWheelViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 13/04/2026.
//

import Foundation
import Combine

// MARK: - ViewModel عجلة الحظ
@MainActor
final class SpinWheelViewModel: ObservableObject {

    // MARK: - State
    @Published var slots: [SpinSlot] = []
    @Published var canSpin = false
    @Published var isSpinning = false
    @Published var resultIndex: Int?
    @Published var resultReward: SpinSlot?
    @Published var showResult = false
    @Published var nextFreeIn: Int = 0
    @Published var extraSpinsUsed: Int = 0
    @Published var maxExtraSpins: Int = 3
    @Published var extraSpinCost: Int = 10

    // MARK: - Dependencies
    private let service = MainService.shared
    private let toast = ToastManager.shared
    private var timer: Timer?

    // MARK: - تحميل الحالة
    func onAppear() async {
        do {
            let status = try await service.getSpinStatus()
            slots = status.slots ?? []
            canSpin = status.canSpin
            nextFreeIn = status.nextFreeInSeconds ?? 0
            extraSpinsUsed = status.extraSpinsUsed ?? 0
            maxExtraSpins = status.maxExtraSpins ?? 3
            extraSpinCost = status.extraSpinCost ?? 10
            startCountdown()
            scheduleReminder()
        } catch {
            toast.error("فشل تحميل العجلة")
        }
    }

    /// جدولة تذكير محلي لوقت توفّر العجلة التالي
    private func scheduleReminder() {
        if canSpin {
            LocalNotificationsManager.cancel(.spinWheel)
        } else if nextFreeIn > 0 {
            LocalNotificationsManager.scheduleSpinWheel(after: TimeInterval(nextFreeIn))
        }
    }

    // MARK: - دوران مجاني
    func spinFree() async {
        guard canSpin, !isSpinning else { return }
        await performSpin(useExtra: false)
    }

    // MARK: - دوران مدفوع
    func spinExtra() async {
        guard !isSpinning, extraSpinsUsed < maxExtraSpins else { return }
        await performSpin(useExtra: true)
    }

    // MARK: - إغلاق النتيجة
    func dismissResult() {
        showResult = false
        resultReward = nil
    }

    // MARK: - Private

    private func performSpin(useExtra: Bool) async {
        isSpinning = true
        HapticManager.medium()

        do {
            let result = try await service.spin(useExtra: useExtra)
            resultIndex = result.slotIndex
            resultReward = result.reward

            // انتظار انتهاء الأنيميشن
            try? await Task.sleep(nanoseconds: 3_500_000_000)

            isSpinning = false
            showResult = true
            HapticManager.success()
            toast.success("🎉 \(result.reward.label)")

            // تحديث الحالة
            await refreshStatus()
        } catch let error as APIError {
            isSpinning = false
            toast.error(error.errorDescription ?? "فشل الدوران")
        } catch {
            isSpinning = false
            toast.error(error.localizedDescription)
        }
    }

    private func refreshStatus() async {
        if let status = try? await service.getSpinStatus() {
            canSpin = status.canSpin
            nextFreeIn = status.nextFreeInSeconds ?? 0
            extraSpinsUsed = status.extraSpinsUsed ?? 0
            startCountdown()
            scheduleReminder()
        }
    }

    private func startCountdown() {
        timer?.invalidate()
        guard nextFreeIn > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.nextFreeIn > 0 {
                    self.nextFreeIn -= 1
                } else {
                    self.canSpin = true
                    self.timer?.invalidate()
                }
            }
        }
    }

    // MARK: - تنسيق الوقت
    var countdownText: String {
        let m = nextFreeIn / 60
        let s = nextFreeIn % 60
        return String(format: "%02d:%02d", m, s)
    }

    deinit {
        timer?.invalidate()
    }
}
