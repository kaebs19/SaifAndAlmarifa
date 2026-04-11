//
//  RoomCodeSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - عرض كود الغرفة
struct RoomCodeSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSizes.Spacing.xl) {
            // الهيدر
            Text(AppStrings.Main.roomCode)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)

            // الكود
            Text(code)
                .font(.poppins(.bold, size: 42))
                .foregroundStyle(AppColors.Default.goldPrimary)
                .kerning(8)
                .padding(.vertical, AppSizes.Spacing.lg)

            // الأزرار
            HStack(spacing: AppSizes.Spacing.md) {
                Button {
                    UIPasteboard.general.string = code
                    HapticManager.success()
                    ToastManager.shared.success(AppStrings.Main.copyCode)
                } label: {
                    Label(AppStrings.Main.copyCode, systemImage: "doc.on.doc")
                        .font(.cairo(.semiBold, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppSizes.Button.medium)
                        .overlay(Capsule().stroke(AppColors.Default.goldPrimary, lineWidth: 1))
                }

                ShareLink(item: "انضم لمعركتي في سيف المعرفة!\nالكود: \(code)") {
                    Label(AppStrings.Main.shareRoom, systemImage: "square.and.arrow.up")
                        .font(.cairo(.semiBold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppSizes.Button.medium)
                        .background(AppColors.Gradients.gold)
                        .clipShape(Capsule())
                }
            }

            Button("إغلاق") { dismiss() }
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(AppSizes.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "0E1236"))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
