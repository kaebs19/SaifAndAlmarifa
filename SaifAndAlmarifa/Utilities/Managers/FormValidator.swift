//
//  FormValidator.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/FormValidator.swift
//  مدير تحقق مركزي — يُستخدم من الـ ViewModels لفحص المدخلات لحظياً

import Foundation

// MARK: - قاعدة تحقق
struct ValidationRule {
    let check: (String) -> Bool
    let message: String
}

// MARK: - نتيجة التحقق
struct ValidationResult {
    let isValid: Bool
    let error: String?

    static let valid = ValidationResult(isValid: true, error: nil)

    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, error: message)
    }
}

// MARK: - Form Validator
enum FormValidator {

    // MARK: - تحقق من حقل واحد بقواعد متعددة
    static func validate(_ value: String, rules: [ValidationRule]) -> ValidationResult {
        for rule in rules {
            if !rule.check(value) {
                return .invalid(rule.message)
            }
        }
        return .valid
    }

    // MARK: - ═══════════════ قواعد جاهزة ═══════════════

    // MARK: مطلوب
    static func required(message: String = "هذا الحقل مطلوب") -> ValidationRule {
        ValidationRule(check: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }, message: message)
    }

    // MARK: حد أدنى للطول
    static func minLength(_ length: Int, message: String? = nil) -> ValidationRule {
        ValidationRule(
            check: { $0.count >= length },
            message: message ?? "يجب أن يكون \(length) أحرف على الأقل"
        )
    }

    // MARK: حد أقصى للطول
    static func maxLength(_ length: Int, message: String? = nil) -> ValidationRule {
        ValidationRule(
            check: { $0.count <= length },
            message: message ?? "يجب ألا يتجاوز \(length) حرفاً"
        )
    }

    // MARK: بريد إلكتروني
    static var email: ValidationRule {
        ValidationRule(
            check: { AuthValidator.isValidEmail($0) },
            message: AppStrings.Errors.emailInvalid
        )
    }

    // MARK: كلمة مرور (8+ أحرف)
    static var password: ValidationRule {
        ValidationRule(
            check: { AuthValidator.isValidPassword($0) },
            message: AppStrings.Errors.passwordTooShort
        )
    }

    // MARK: تطابق حقلين
    static func matches(_ other: String, message: String = AppStrings.Errors.passwordsDoNotMatch) -> ValidationRule {
        ValidationRule(check: { $0 == other }, message: message)
    }

    // MARK: - ═══════════════ مجموعات جاهزة ═══════════════

    static var usernameRules: [ValidationRule] {
        [
            required(message: AppStrings.Errors.usernameRequired),
            minLength(3, message: AppStrings.Errors.usernameTooShort),
            maxLength(20, message: "اسم المستخدم طويل جداً")
        ]
    }

    static var emailRules: [ValidationRule] {
        [
            required(message: AppStrings.Errors.emailRequired),
            email
        ]
    }

    static var passwordRules: [ValidationRule] {
        [
            required(message: AppStrings.Errors.passwordRequired),
            password
        ]
    }

    static func confirmPasswordRules(matching password: String) -> [ValidationRule] {
        [
            required(message: AppStrings.Errors.passwordRequired),
            matches(password)
        ]
    }
}
