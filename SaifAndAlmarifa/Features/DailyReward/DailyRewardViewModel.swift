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

            // تحديث الحالة
            await onAppear()
        } catch let error as APIError {
            toast.error(error.errorDescription ?? "فشل المطالبة")
        } catch {
            toast.error(error.localizedDescription)
        }
    }
}
