//
//  GradientButton.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/GradientButton.swift
//  زر بتدرج لوني مع تأثير التوهج
//  تُستخدم في: Login, Register, Profile ...

import SwiftUI

struct GradientButton: View {
    
    // MARK: - Properties
    let title: String
    var icon: String? = nil
    var foreground: Color = .white
    var colors: [Color] = [AppColors.Default.primary, AppColors.Default.accent]
    var disabledColors: [Color] = [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var height: CGFloat = AppSizes.Button.large
    var cornerRadius: CGFloat = AppSizes.Radius.medium
    var font: Font = .cairo(.bold, size: AppSizes.Font.bodyLarge)
    var glowEnabled: Bool = true
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Gradient Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? colors : disabledColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: glowColor,
                        radius: 10,
                        x: 0,
                        y: 5
                    )

                // Content
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else {
                    HStack(spacing: AppSizes.Spacing.sm) {
                        Text(title)
                            .font(font)
                        if let icon {
                            Image(icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                    }
                    .foregroundStyle(foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.7)
        .animation(.easeInOut(duration: 0.25), value: isEnabled)
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }

    // MARK: - Helpers
    private func handleTap() {
        guard isEnabled, !isLoading else { return }
        action()
    }

    private var glowColor: Color {
        guard isEnabled, glowEnabled, let first = colors.first else { return .clear }
        return first.opacity(0.4)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GradientBackground.main
        
        VStack(spacing: 16) {
            GradientButton(title: "تسجيل الدخول") { }
            
            GradientButton(title: "معطّل", isEnabled: false) { }
            
            GradientButton(title: "جاري التحميل", isLoading: true) { }
            
            GradientButton(
                title: "ستايل مخصص",
                colors: [.purple, .blue],
                cornerRadius: AppSizes.Radius.xl
            ) { }
        }
        .padding()
    }
}
