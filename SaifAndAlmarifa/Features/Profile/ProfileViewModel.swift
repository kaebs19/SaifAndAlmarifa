//
//  ProfileViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 13/04/2026.
//

import Foundation
import Combine
import UIKit

// MARK: - ViewModel الملف الشخصي
@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - State
    @Published var isLoading = false
    @Published var isEditing = false
    @Published var editUsername = ""
    @Published var editCountry: Country = CountryList.detect()
    @Published var avatars: [DefaultAvatarItem] = []
    @Published var showAvatarPicker = false

    // MARK: - إحصائيات اللعب
    @Published var stats: UserStats?

    // MARK: - Dependencies
    private let authService = AuthService.shared
    private let mainService = MainService.shared
    private let authManager = AuthManager.shared
    private let toast = ToastManager.shared

    var user: User? { authManager.currentUser }

    // MARK: - تحميل البيانات
    func onAppear() async {
        // جلب بالتوازي
        async let userFetch: Void = { _ = try? await authService.getMe() }()
        async let avatarsFetch = mainService.getAvatars()
        async let statsFetch = mainService.getUserStats()

        _ = await userFetch
        avatars = (try? await avatarsFetch) ?? []
        stats = try? await statsFetch

        if let user {
            editUsername = user.username
            editCountry = CountryList.all.first { $0.id == user.country } ?? CountryList.detect()
        }
    }

    // MARK: - بدء التعديل
    func startEditing() {
        editUsername = user?.username ?? ""
        editCountry = CountryList.all.first { $0.id == user?.country } ?? CountryList.detect()
        isEditing = true
    }

    // MARK: - حفظ التعديلات
    func saveProfile() async {
        guard !editUsername.trimmingCharacters(in: .whitespaces).isEmpty else {
            toast.warning("اسم المستخدم مطلوب")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await authService.updateProfile(
                username: editUsername,
                country: editCountry.id
            )
            isEditing = false
            HapticManager.success()
            toast.success("تم تحديث الملف الشخصي")
        } catch let error as APIError {
            toast.error(error.errorDescription ?? "فشل التحديث")
        } catch {
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - اختيار أفاتار
    func selectAvatar(_ avatar: DefaultAvatarItem) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await authService.selectAvatar(id: avatar.id)
            HapticManager.success()
            toast.success("تم تغيير الصورة")
        } catch let error as APIError {
            toast.error(error.errorDescription ?? "فشل تغيير الصورة")
        } catch {
            toast.error(error.localizedDescription)
        }
    }

    // MARK: - نسخ كود الصداقة
    func copyFriendCode() {
        guard let code = user?.friendCode else { return }
        UIPasteboard.general.string = code
        HapticManager.success()
        toast.success("تم نسخ الكود: \(code)")
    }

    // MARK: - تسجيل الخروج
    func logout() {
        authService.logout()
    }
}
