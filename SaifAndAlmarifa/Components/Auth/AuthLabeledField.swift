//
//  AuthLabeledField.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/AuthLabeledField.swift

import SwiftUI

// MARK: - حقل مع Label فوقه
struct AuthLabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            Text(label)
                .font(.cairo(.semiBold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
            content()
        }
    }
}
