//
//  GemStoreView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import SwiftUI
import StoreKit

// MARK: - شاشة شراء الجواهر
struct GemStoreView: View {
    @StateObject private var iap = IAPManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            currentBalance

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSizes.Spacing.md) {
                    ForEach(GemPackage.allCases) { pkg in
                        packageCard(pkg)
                    }
                }
                .padding(AppSizes.Spacing.lg)
            }

            restoreButton
        }
        .background(GradientBackground.main)
        .task { await iap.loadProducts() }
    }

    // MARK: الهيدر
    private var header: some View {
        ZStack {
            Text("متجر الجواهر 💎")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(AppSizes.Spacing.lg)
    }

    // MARK: الرصيد الحالي
    private var currentBalance: some View {
        HStack(spacing: AppSizes.Spacing.xl) {
            HStack(spacing: 6) {
                Text("💎").font(.system(size: 22))
                Text("\(AuthManager.shared.currentUser?.gems ?? 0)")
                    .font(.poppins(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(Color(hex: "60A5FA"))
            }
            HStack(spacing: 6) {
                Text("🪙").font(.system(size: 22))
                Text("\(AuthManager.shared.currentUser?.gold ?? 0)")
                    .font(.poppins(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(Color(hex: "FFD700"))
            }
        }
        .padding(.bottom, AppSizes.Spacing.md)
    }

    // MARK: بطاقة باقة
    private func packageCard(_ pkg: GemPackage) -> some View {
        let product = iap.products.first { $0.id == pkg.rawValue }

        return Button {
            guard let product else { return }
            Task { await iap.purchase(product) }
        } label: {
            HStack(spacing: AppSizes.Spacing.md) {
                // الأيقونة
                Image(systemName: pkg.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "60A5FA"), Color(hex: "3B82F6")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 50, height: 50)
                    .background(Color(hex: "60A5FA").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small))

                // التفاصيل
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(pkg.nameAr)
                            .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                            .foregroundStyle(.white)

                        if pkg.isPopular {
                            Text("شائع")
                                .font(.cairo(.bold, size: 9))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.Default.info)
                                .clipShape(Capsule())
                        }
                        if pkg.isBestValue {
                            Text("أفضل قيمة")
                                .font(.cairo(.bold, size: 9))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.Default.success)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 4) {
                        Text("\(pkg.gems) 💎")
                            .font(.cairo(.medium, size: AppSizes.Font.body))
                            .foregroundStyle(Color(hex: "60A5FA"))
                        if pkg.bonusGold > 0 {
                            Text("+ \(pkg.bonusGold) 🪙")
                                .font(.cairo(.medium, size: AppSizes.Font.body))
                                .foregroundStyle(Color(hex: "FFD700"))
                        }
                    }
                }

                Spacer()

                // السعر
                Text(product?.displayPrice ?? "...")
                    .font(.poppins(.bold, size: AppSizes.Font.bodyLarge))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .padding(.horizontal, AppSizes.Spacing.md)
                    .padding(.vertical, AppSizes.Spacing.xs)
                    .background(AppColors.Default.goldPrimary.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppColors.Default.goldPrimary.opacity(0.3), lineWidth: 1))
            }
            .padding(AppSizes.Spacing.md)
            .background(.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(
                        pkg == .king
                            ? AppColors.Default.goldPrimary.opacity(0.4)
                            : .white.opacity(0.08),
                        lineWidth: pkg == .king ? 2 : 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(iap.isPurchasing || product == nil)
        .opacity(iap.isPurchasing ? 0.6 : 1)
    }

    // MARK: استعادة المشتريات
    private var restoreButton: some View {
        Button {
            Task { await iap.restorePurchases() }
        } label: {
            Text("استعادة المشتريات")
                .font(.cairo(.medium, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(AppSizes.Spacing.md)
    }
}
