//
//  PasswordStrengthBar.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/PasswordStrengthBar.swift
//  شريط قوة كلمة المرور + مؤشر تطابق

import SwiftUI

// MARK: - مستوى القوة
enum PasswordStrength: Int, CaseIterable {
    case empty = 0
    case weak = 1
    case medium = 2
    case strong = 3

    var label: String {
        switch self {
        case .empty:  return ""
        case .weak:   return "ضعيفة"
        case .medium: return "متوسطة"
        case .strong: return "قوية"
        }
    }

    var color: Color {
        switch self {
        case .empty:  return .clear
        case .weak:   return AppColors.Default.error
        case .medium: return AppColors.Default.warning
        case .strong: return AppColors.Default.success
        }
    }

    // MARK: حساب القوة
    static func evaluate(_ password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .empty }
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }

        switch score {
        case 0...1: return .weak
        case 2:     return .medium
        default:    return .strong
        }
    }
}

// MARK: - شريط قوة كلمة المرور
struct PasswordStrengthBar: View {
    let password: String

    private var strength: PasswordStrength {
        PasswordStrength.evaluate(password)
    }

    var body: some View {
        if !password.isEmpty {
            VStack(spacing: AppSizes.Spacing.xs) {
                // الشريط
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { level in
                        Capsule()
                            .fill(level <= strength.rawValue ? strength.color : .white.opacity(0.15))
                            .frame(height: 4)
                    }
                }

                // النص
                HStack {
                    Spacer()
                    Text(strength.label)
                        .font(.cairo(.medium, size: AppSizes.Font.caption))
                        .foregroundStyle(strength.color)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: strength)
        }
    }
}

// MARK: - علامة تطابق كلمة المرور
struct PasswordMatchIndicator: View {
    let password: String
    let confirmPassword: String

    private var isMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var showMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    var body: some View {
        if !confirmPassword.isEmpty {
            HStack(spacing: AppSizes.Spacing.xs) {
                Image(systemName: isMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 13))
                Text(isMatch ? "كلمتا المرور متطابقتان" : "كلمتا المرور غير متطابقتين")
                    .font(.cairo(.regular, size: AppSizes.Font.caption))
                Spacer()
            }
            .foregroundStyle(isMatch ? AppColors.Default.success : AppColors.Default.error)
            .animation(.easeInOut(duration: 0.2), value: isMatch)
        }
    }
}

#Preview {
    ZStack {
        GradientBackground.main
        VStack(spacing: 20) {
            PasswordStrengthBar(password: "abc")
            PasswordStrengthBar(password: "abcdefgh")
            PasswordStrengthBar(password: "Abcdef1!")
            PasswordMatchIndicator(password: "Test123!", confirmPassword: "Test123!")
            PasswordMatchIndicator(password: "Test123!", confirmPassword: "Test")
        }
        .padding()
    }
}
