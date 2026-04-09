//
//  GlassCard.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/GlassCard.swift
//  كارد زجاجي (Glass Morphism) قابل لإعادة الاستخدام
//  تُستخدم في: Login, Register, Profile, Settings ...

import SwiftUI

struct GlassCard<Content: View>: View {
    
    // MARK: - Properties
    var cornerRadius: CGFloat = AppSizes.Radius.large
    var padding: CGFloat = AppSizes.Spacing.lg
    var borderOpacity: Double = 0.3
    var shadowRadius: CGFloat = 20
    @ViewBuilder let content: Content
    
    // MARK: - Body
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(borderOpacity),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: shadowRadius, x: 0, y: 10)
            )
    }
}

// MARK: - View Modifier (بديل)
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppSizes.Radius.large
    var padding: CGFloat = AppSizes.Spacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
    }
}

extension View {
    /// تطبيق ستايل الكارد الزجاجي على أي View
    ///
    /// ```swift
    /// VStack { ... }
    ///     .glassCard()
    ///     .glassCard(cornerRadius: 20, padding: 24)
    /// ```
    func glassCard(
        cornerRadius: CGFloat = AppSizes.Radius.large,
        padding: CGFloat = AppSizes.Spacing.lg
    ) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GradientBackground.main
        
        GlassCard {
            VStack(spacing: 16) {
                Text("كارد زجاجي")
                    .font(.cairo(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)
                
                Text("يمكن استخدامه في أي شاشة")
                    .font(.cairo(.regular, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
    }
}
