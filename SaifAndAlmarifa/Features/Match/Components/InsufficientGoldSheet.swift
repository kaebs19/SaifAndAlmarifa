//
//  InsufficientGoldSheet.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/InsufficientGoldSheet.swift
//  Sheet يظهر لو المستخدم ما عنده ذهب كافي للرهن — مع خيار إعلان
//

import SwiftUI

struct InsufficientGoldSheet: View {
    let currentGold: Int
    let requiredGold: Int
    let onWatchAd: () -> Void
    let onOpenStore: () -> Void
    let onCancel: () -> Void

    @StateObject private var adManager = AdManager.shared
    @State private var isLoadingReward = false

    var body: some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            // Header
            VStack(spacing: AppSizes.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "FFD700").opacity(0.4), .clear],
                                center: .center, startRadius: 10, endRadius: 60
                            )
                        )
                        .frame(width: 110, height: 110)
                        .blur(radius: 4)
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 70, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: 14)
                }
                .frame(height: 120)

                Text("ذهب غير كافٍ")
                    .font(.cairo(.black, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)

                Text("تحتاج \(requiredGold) ذهب لدخول هذي المباراة")
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppSizes.Spacing.lg)

            // الرصيد الحالي
            HStack(spacing: 6) {
                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.5))
                Text("رصيدك الحالي:")
                    .font(.cairo(.medium, size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(currentGold)")
                    .font(.poppins(.black, size: 14))
                    .foregroundStyle(Color(hex: "FFD700"))
                    .monospacedDigit()
                Text("ذهب")
                    .font(.cairo(.medium, size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.white.opacity(0.05))
            .clipShape(Capsule())

            Spacer()

            // الأزرار
            VStack(spacing: 10) {
                // 📺 شاهد إعلان
                Button {
                    HapticManager.medium()
                    watchAd()
                } label: {
                    HStack(spacing: 8) {
                        if isLoadingReward {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "play.tv.fill")
                                .font(.system(size: 18, weight: .black))
                        }
                        Text(isLoadingReward
                             ? "جاري عرض الإعلان..."
                             : "شاهد إعلان واربح 100 ذهب")
                            .font(.cairo(.black, size: AppSizes.Font.body))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "10B981"), Color(hex: "059669")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color(hex: "10B981").opacity(0.5), radius: 10)
                }
                .disabled(isLoadingReward || !adManager.isRewardedAdReady)
                .opacity(adManager.isRewardedAdReady ? 1 : 0.6)

                // 🛒 افتح المتجر
                Button {
                    HapticManager.light()
                    onOpenStore()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bag.badge.plus")
                            .font(.system(size: 16, weight: .black))
                        Text("اشترِ ذهب من المتجر")
                            .font(.cairo(.bold, size: AppSizes.Font.body))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // إلغاء
                Button {
                    HapticManager.light()
                    onCancel()
                } label: {
                    Text("إلغاء")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "08091E"), Color(hex: "12103B")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func watchAd() {
        isLoadingReward = true
        adManager.showRewardedAd { rewarded in
            guard rewarded else {
                isLoadingReward = false
                return
            }
            // أرسل للسيرفر يضيف الذهب
            Task { @MainActor in
                do {
                    let result = try await MainService.shared.claimAdReward()
                    // حدّث رصيد المستخدم
                    if let me = try? await AuthService.shared.getMe() {
                        AuthManager.shared.updateCurrentUser(me)
                    }
                    isLoadingReward = false
                    ToastManager.shared.success("🎉 +\(result.goldGranted) ذهب!")
                    onWatchAd()
                } catch {
                    isLoadingReward = false
                    ToastManager.shared.error("فشل تحصيل المكافأة")
                }
            }
        }
    }
}
