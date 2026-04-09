//
//  GradientBackground.swift
//  DatingHala
//
//  Created by Mohammed Saleh on 04/03/2026.
//

//  Path: SaifAndAlmarifa/Components/GradientBackground.swift
//  خلفية متدرجة قابلة لإعادة الاستخدام
//  تُستخدم في: Login, Register, Onboarding, ForgotPassword ...

import SwiftUI

struct GradientBackground: View {
    
    // MARK: - Properties
    var topColor: Color = Color(hex: "1A0A2E")
    var middleColor: Color = Color(hex: "2D1B69")
    var bottomColor: Color = Color(hex: "11001C")
    var startPoint: UnitPoint = .topLeading
    var endPoint: UnitPoint = .bottomTrailing
    
    // MARK: - Body
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [topColor, middleColor, bottomColor]),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preset Styles
extension GradientBackground {
    
    /// الستايل الأساسي للتطبيق (بنفسجي غامق)
    static var main: GradientBackground {
        GradientBackground()
    }
    
    /// ستايل رومانسي (وردي)
    static var romantic: GradientBackground {
        GradientBackground(
            topColor: Color(hex: "2D0A1A"),
            middleColor: Color(hex: "4A1942"),
            bottomColor: Color(hex: "11001C")
        )
    }
    
    /// ستايل داكن (للشاشات الداخلية)
    static var dark: GradientBackground {
        GradientBackground(
            topColor: AppColors.Default.background,
            middleColor: Color(hex: "0D0010"),
            bottomColor: Color(hex: "050008")
        )
    }
}

// MARK: - View Modifier
/// استخدمها كـ modifier على أي View
struct GradientBackgroundModifier: ViewModifier {
    var style: GradientBackground = .main
    
    func body(content: Content) -> some View {
        ZStack {
            style
            content
        }
    }
}

extension View {
    /// تطبيق خلفية متدرجة على أي View
    ///
    /// ```swift
    /// ScrollView { ... }
    ///     .gradientBackground()          // الأساسي
    ///     .gradientBackground(.romantic)  // وردي
    /// ```
    func gradientBackground(_ style: GradientBackground = .main) -> some View {
        self.modifier(GradientBackgroundModifier(style: style))
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Text("خلفية متدرجة")
            .font(.cairo(.bold, size: AppSizes.Font.title1))
            .foregroundStyle(.white)
    }
    .gradientBackground()
}
