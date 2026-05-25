//
//  AchievementsViewModel.swift
//  SaifAndAlmarifa
//

import Foundation
import Combine

@MainActor
final class AchievementsViewModel: ObservableObject {

    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = AchievementsService.shared
    private let toast = ToastManager.shared

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked == true }.count
    }

    var totalCount: Int { achievements.count }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            achievements = try await service.getMine()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            toast.error("فشل تحميل الإنجازات")
        }
    }
}
