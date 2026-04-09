//
//  DividerWithText.swift
//  DatingHala
//
//  Created by Mohammed Saleh on 26/01/2026.
//

//  Path: SaifAndAlmarifa/Components/DividerWithText.swift
//  فاصل مع نص
//  ✅ محسّن: يدعم الثيم الداكن والفاتح

import SwiftUI

// MARK: - Divider Style
enum DividerStyle {
    case light
    case glass
    case auto
}

struct DividerWithText: View {
    let text: String
    var style: DividerStyle = .auto
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var resolvedStyle: DividerStyle {
        if style != .auto { return style }
        return colorScheme == .dark ? .glass : .light
    }
    
    private var lineColor: Color {
        resolvedStyle == .glass ? .white.opacity(0.15) : Color.gray.opacity(0.3)
    }
    
    private var textColor: Color {
        resolvedStyle == .glass ? .white.opacity(0.4) : .gray
    }
    
    var body: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            line
            
            Text(text)
                .font(.cairo(.regular, size: AppSizes.Font.bodyLarge))
                .foregroundColor(textColor)
            
            line
        }
    }
    
    private var line: some View {
        Rectangle()
            .fill(lineColor)
            .frame(height: 1)
    }
}

// MARK: - Preview
#Preview("Light") {
    DividerWithText(text: "أو", style: .light)
        .padding()
}

#Preview("Glass") {
    ZStack {
        GradientBackground.main
        DividerWithText(text: "أو", style: .glass)
            .padding()
    }
}
