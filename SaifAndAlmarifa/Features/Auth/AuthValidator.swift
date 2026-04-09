//
//  AuthValidator.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/AuthValidator.swift

import Foundation

// MARK: - مُحقّق مدخلات Auth (مشترك بين Login و Register)
enum AuthValidator {

    // MARK: - Email
    static func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    // MARK: - Password
    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 8
    }

    // MARK: - Username
    static func isValidUsername(_ username: String) -> Bool {
        username.trimmingCharacters(in: .whitespaces).count >= 3
    }
}
