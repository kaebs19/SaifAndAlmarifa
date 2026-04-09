//
//  AuthFlow.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Auth/AuthFlow.swift

import SwiftUI

// MARK: - مسارات Auth
enum AuthRoute: Hashable {
    case register
    case login
    case forgotPassword
}

// MARK: - تدفق شاشات Auth
struct AuthFlow: View {

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onRegister: { path.append(AuthRoute.register) },
                onLogin:    { path.append(AuthRoute.login) }
            )
            .navigationBarHidden(true)
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .register:
                    RegisterView(
                        onBack: { path.removeLast() },
                        onGoToLogin: {
                            path.removeLast()
                            path.append(AuthRoute.login)
                        }
                    )
                    .navigationBarHidden(true)
                case .login:
                    LoginView(
                        onBack: { path.removeLast() },
                        onGoToRegister: {
                            path.removeLast()
                            path.append(AuthRoute.register)
                        },
                        onForgotPassword: {
                            path.append(AuthRoute.forgotPassword)
                        }
                    )
                    .navigationBarHidden(true)

                case .forgotPassword:
                    ForgotPasswordView(
                        onBack:     { path.removeLast() },
                        onComplete: { path.removeLast() }
                    )
                    .navigationBarHidden(true)
                }
            }
        }
    }
}

#Preview {
    AuthFlow()
        .environment(\.layoutDirection, .rightToLeft)
}
