//
//  DailyRewardViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation
import Combine

// MARK: - ViewModel المكافأة اليومية
@MainActor
final class DailyRewardViewModel: ObservableObject {

    @Published var status: DailyRewardStatus?
    @Published var isLoading = false
    @Published var claimedReward: DailyRewardItem?
    @Published var showClaimed = false

    private let service = MainService.shared
    private let toast = ToastManager.shared

    // MARK: - تحميل الحالة
    func onAppear() async {
        isLoading = true
        defer { isLoading = false }
        status = try? await service.getDailyRewardStatus()
        scheduleReminder()
    }

    // MARK: - المطالبة بالمكافأة
    func claim() async {
        guard status?.claimed == false else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.claimDailyReward()
            claimedReward = result.reward
            showClaimed = true
            HapticManager.success()
            toast.success("🎁 \(result.reward.label)")

            // تحديث الحالة + جدولة تذكير بكرة
            await onAppear()
        } catch let error as APIError {
            toast.error(error.errorDescription ?? "فشل المطالبة")
        } catch {
            toast.error(error.localizedDescription)
        }
    }

    /// جدولة تذكير محلي بكرة (منتصف الليل) لو المكافأة تم استلامها
    private func scheduleReminder() {
        guard let s = status else { return }
        if s.claimed {
            // المكافأة القادمة = منتصف الليل التالي
            let now = Date()
            let cal = Calendar.current
            if let tomorrow = cal.nextDate(
                after: now,
                matching: DateComponents(hour: 0, minute: 0),
                matchingPolicy: .nextTime
            ) {
                let seconds = tomorrow.timeIntervalSince(now)
                LocalNotificationsManager.scheduleDailyReward(after: seconds)
            }
        } else {
            // المكافأة جاهزة — ألغِ أي تذكير قائم
            LocalNotificationsManager.cancel(.dailyReward)
        }
    }
}
