//
//  AuthBackButton.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/AuthBackButton.swift

import SwiftUI

// MARK: - زر الرجوع لشاشات Auth
struct AuthBackButton: View {
    var action: () -> Void

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        Button(action: action) {
            Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.Default.goldPrimary)
                .frame(width: 40, height: 40)
        }
    }
}

#Preview {
    ZStack {
        GradientBackground.main
        AuthBackButton { }
    }
}
