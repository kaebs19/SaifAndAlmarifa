//
//  GlowImage.swift
//  DatingHala
//
//  Created by Mohammed Saleh on 04/03/2026.
//

//  Path: SaifAndAlmarifa/Components/GlowImage.swift
//  صورة مع تأثير التوهج (Glow) قابلة لإعادة الاستخدام
//  تُستخدم في: Login Header, Profile, Onboarding ...

import SwiftUI

struct GlowImage: View {
    
    // MARK: - Properties
    let imageName: String
    var size: CGFloat = 130
    var glowColor: Color = AppColors.Default.primary
    var glowRadius: CGFloat = 100
    var glowOpacity: Double = 0.3
    var borderColors: [Color] = [
        AppColors.Default.primary,
        AppColors.Default.accent
    ]
    var borderWidth: CGFloat = 3
    var shadowRadius: CGFloat = 15
    var isCircle: Bool = true
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Glow Effect خلف الصورة
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(glowOpacity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: glowRadius
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 20)
            
            // الصورة
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: borderColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth
                        )
                )
                .shadow(
                    color: glowColor.opacity(glowOpacity + 0.1),
                    radius: shadowRadius,
                    x: 0,
                    y: 5
                )
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GradientBackground.main

        GlowImage(imageName: "logo")
    }
}
