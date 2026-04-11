//
//  HomeView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Home/HomeView.swift
//  شاشة رئيسية مؤقتة لاختبار Auth + عرض بيانات المستخدم

import SwiftUI

// MARK: - الشاشة الرئيسية (اختبار)
struct HomeView: View {

    @StateObject private var authManager = AuthManager.shared
    @StateObject private var socketManager = AppSocketManager.shared
    @State private var showLogoutAlert = false
    @State private var activeContentPage: ContentPageKey?
    @State private var showContactUs = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSizes.Spacing.lg) {
                header
                profileCard
                sessionInfoCard
                socketStatusCard
                contentLinksCard
                logoutButton
            }
            .padding(AppSizes.Spacing.lg)
        }
        .background(GradientBackground.main)
        .alert("تسجيل الخروج", isPresented: $showLogoutAlert) {
            Button("خروج", role: .destructive) {
                AuthService.shared.logout()
            }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("هل تريد تسجيل الخروج؟")
        }
    }

    // MARK: الهيدر
    private var header: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            Image("icon_swords_crossed")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .shadow(color: AppColors.Default.goldPrimary.opacity(0.5), radius: 15)

            Text(AppStrings.Auth.appTitle)
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(AppColors.Default.goldPrimary)
        }
    }

    // MARK: بطاقة الملف الشخصي
    private var profileCard: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            sectionTitle("الملف الشخصي")

            if let user = authManager.currentUser {
                VStack(spacing: 0) {
                    profileRow(icon: "person.fill", label: "الاسم", value: user.username)
                    divider
                    profileRow(icon: "envelope.fill", label: "البريد", value: user.email)
                    divider
                    profileRow(icon: "flag.fill", label: "الدولة", value: user.country ?? "—")
                    divider
                    profileRow(icon: "shield.fill", label: "الدور", value: roleLabel(user.role))
                    divider
                    profileRow(icon: "star.fill", label: "المستوى", value: "\(user.level ?? 1)")
                    divider
                    profileRow(icon: "diamond.fill", label: "الجواهر", value: "\(user.gems ?? 0)")
                }
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
            } else {
                Text("لا توجد بيانات مستخدم")
                    .font(.cairo(.regular, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }

    // MARK: بطاقة معلومات الجلسة
    private var sessionInfoCard: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            sectionTitle("الجلسة")

            VStack(spacing: 0) {
                profileRow(
                    icon: "key.fill",
                    label: "Token",
                    value: tokenPreview
                )
                divider
                profileRow(
                    icon: "number",
                    label: "User ID",
                    value: idPreview
                )
                divider
                profileRow(
                    icon: "checkmark.circle.fill",
                    label: "الحالة",
                    value: authManager.isAuthenticated ? "مُسجّل" : "غير مُسجّل",
                    valueColor: authManager.isAuthenticated ? .green : .red
                )
            }
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: حالة Socket
    private var socketStatusCard: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            sectionTitle("Socket.io")

            HStack {
                Circle()
                    .fill(socketColor)
                    .frame(width: 10, height: 10)

                Text(socketLabel)
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    if socketManager.state == .connected {
                        socketManager.disconnect()
                    } else {
                        socketManager.connect()
                    }
                } label: {
                    Text(socketManager.state == .connected ? "قطع" : "اتصال")
                        .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                        .padding(.horizontal, AppSizes.Spacing.md)
                        .padding(.vertical, AppSizes.Spacing.xs)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSizes.Radius.small)
                                .stroke(AppColors.Default.goldPrimary, lineWidth: 1)
                        )
                }
            }
            .padding(AppSizes.Spacing.md)
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: زر تسجيل الخروج
    private var logoutButton: some View {
        Button {
            showLogoutAlert = true
        } label: {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("تسجيل الخروج")
                    .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .frame(height: AppSizes.Button.large)
            .background(.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: صفحات المحتوى
    private var contentLinksCard: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            sectionTitle("صفحات المحتوى")

            VStack(spacing: 0) {
                contentLink(icon: "doc.text.fill", label: AppStrings.Settings.privacy) {
                    activeContentPage = .privacyPolicy
                }
                divider
                contentLink(icon: "doc.plaintext.fill", label: "شروط الاستخدام") {
                    activeContentPage = .termsOfUse
                }
                divider
                contentLink(icon: "info.circle.fill", label: AppStrings.Settings.about) {
                    activeContentPage = .aboutApp
                }
                divider
                contentLink(icon: "phone.fill", label: "اتصل بنا") {
                    showContactUs = true
                }
            }
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .fullScreenCover(item: $activeContentPage) { key in
            contentPageDestination(key)
        }
        .fullScreenCover(isPresented: $showContactUs) {
            ContactUsView { showContactUs = false }
        }
    }

    private func contentLink(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .frame(width: 24)
                Text(label)
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                Spacer()
                RTLChevron()
            }
            .padding(.horizontal, AppSizes.Spacing.md)
            .padding(.vertical, AppSizes.Spacing.sm)
        }
    }

    @ViewBuilder
    private func contentPageDestination(_ key: ContentPageKey) -> some View {
        switch key {
        case .privacyPolicy:
            ContentPageView(pageKey: .privacyPolicy, title: AppStrings.Settings.privacy) {
                activeContentPage = nil
            }
        case .termsOfUse:
            ContentPageView(pageKey: .termsOfUse, title: "شروط الاستخدام") {
                activeContentPage = nil
            }
        case .aboutApp:
            ContentPageView(pageKey: .aboutApp, title: AppStrings.Settings.about) {
                activeContentPage = nil
            }
        case .contactUs:
            ContactUsView { activeContentPage = nil }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private func profileRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .white.opacity(0.8)
    ) -> some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.Default.goldPrimary)
                .frame(width: 24)

            Text(label)
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.poppins(.medium, size: AppSizes.Font.body))
                .foregroundStyle(valueColor)
                .lineLimit(1)
        }
        .padding(.horizontal, AppSizes.Spacing.md)
        .padding(.vertical, AppSizes.Spacing.sm)
    }

    private var divider: some View {
        Divider().overlay(.white.opacity(0.06))
    }

    private var tokenPreview: String {
        guard let token = authManager.currentToken else { return "—" }
        return String(token.suffix(16)) + "..."
    }

    private var idPreview: String {
        guard let id = authManager.currentUser?.id else { return "—" }
        return String(id.prefix(8)) + "..."
    }

    private func roleLabel(_ role: String?) -> String {
        switch role {
        case "admin": return "مدير"
        case "player": return "لاعب"
        default: return role ?? "—"
        }
    }

    private var socketColor: Color {
        switch socketManager.state {
        case .connected:    return .green
        case .connecting:   return .yellow
        case .disconnected: return .red
        }
    }

    private var socketLabel: String {
        switch socketManager.state {
        case .connected:    return "متصل"
        case .connecting:   return "جاري الاتصال..."
        case .disconnected: return "غير متصل"
        }
    }
}

#Preview {
    HomeView()
        .environment(\.layoutDirection, .rightToLeft)
}
