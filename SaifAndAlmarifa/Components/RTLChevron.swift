//
//  RTLChevron.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/RTLChevron.swift
//  سهم تنقل يدعم اتجاه الـ RTL تلقائياً

import SwiftUI

/// سهم تنقل يتكيف مع اتجاه اللغة (RTL/LTR)
/// - في العربية: يظهر متجهاً لليسار
/// - في الإنجليزية: يظهر متجهاً لليمين
struct RTLChevron: View {

    // MARK: - Properties
    var size: CGFloat = 13
    var weight: Font.Weight = .medium
    var color: Color = AppColors.Default.textMuted

    @Environment(\.layoutDirection) private var layoutDirection

    // MARK: - Body
    var body: some View {
        Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
            .font(.system(size: size, weight: weight))
            .foregroundStyle(color)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        RTLChevron()
        RTLChevron(size: 18, weight: .bold, color: AppColors.Default.primary)
    }
    .padding()
}
