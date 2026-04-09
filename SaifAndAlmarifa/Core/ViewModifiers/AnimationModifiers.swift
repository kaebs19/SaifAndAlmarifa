//
//  AnimationModifiers.swift
//  DatingHala
//
//  Created by Mohammed Saleh on 04/03/2026.
//

//  Path: SaifAndAlmarifa/Core/ViewModifiers/AnimationModifiers.swift
//  تأثيرات أنيميشن قابلة لإعادة الاستخدام
//  تُستخدم في: Login, Register, Onboarding, أي شاشة تحتاج ظهور تدريجي

import SwiftUI

// MARK: - Staggered Appear (ظهور تدريجي)
/// يجعل العنصر يظهر بأنيميشن مع تأخير
///
/// ```swift
/// VStack {
///     Text("عنوان").staggeredAppear(order: 0)
///     Text("وصف").staggeredAppear(order: 1)
///     Button("زر").staggeredAppear(order: 2)
/// }
/// ```
struct StaggeredAppearModifier: ViewModifier {
    let order: Int
    let baseDelay: Double
    let duration: Double
    let offsetY: CGFloat
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offsetY)
            .onAppear {
                withAnimation(
                    .easeOut(duration: duration)
                    .delay(baseDelay + Double(order) * 0.15)
                ) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Scale Appear (ظهور مع تكبير)
struct ScaleAppearModifier: ViewModifier {
    let delay: Double
    let duration: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.5)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    
    /// ظهور تدريجي بالترتيب
    /// - Parameters:
    ///   - order: ترتيب الظهور (0, 1, 2, ...)
    ///   - baseDelay: التأخير الأساسي قبل بدء الأنيميشن
    ///   - duration: مدة الأنيميشن
    ///   - offsetY: مقدار الإزاحة العمودية
    func staggeredAppear(
        order: Int,
        baseDelay: Double = 0.1,
        duration: Double = 0.6,
        offsetY: CGFloat = 25
    ) -> some View {
        self.modifier(
            StaggeredAppearModifier(
                order: order,
                baseDelay: baseDelay,
                duration: duration,
                offsetY: offsetY
            )
        )
    }
    
    /// ظهور مع تأثير التكبير
    func scaleAppear(delay: Double = 0, duration: Double = 0.6) -> some View {
        self.modifier(ScaleAppearModifier(delay: delay, duration: duration))
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GradientBackground.main
        
        VStack(spacing: 20) {
            Text("عنوان")
                .font(.cairo(.bold, size: 28))
                .foregroundStyle(.white)
                .scaleAppear()
            
            Text("عنصر 1")
                .foregroundStyle(.white)
                .staggeredAppear(order: 0)
            
            Text("عنصر 2")
                .foregroundStyle(.white)
                .staggeredAppear(order: 1)
            
            Text("عنصر 3")
                .foregroundStyle(.white)
                .staggeredAppear(order: 2)
        }
    }
}
