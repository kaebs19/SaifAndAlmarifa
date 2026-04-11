//
//  JoinRoomSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - الانضمام بكود غرفة
struct JoinRoomSheet: View {
    let onJoin: (String) -> Void
    @State private var code = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSizes.Spacing.xl) {
            Text(AppStrings.Main.joinRoom)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)

            AppTextField(
                placeholder: AppStrings.Main.enterCode,
                text: $code,
                icon: "number",
                keyboardType: .numberPad,
                contentType: .oneTimeCode,
                submitLabel: .join,
                style: .glass
            ) {
                submit()
            }

            GradientButton(
                title: AppStrings.Main.join,
                icon: "icon_swords_crossed",
                colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                isEnabled: code.count >= 4
            ) { submit() }

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

    private func submit() {
        guard code.count >= 4 else { return }
        HapticManager.medium()
        onJoin(code)
        dismiss()
    }
}
