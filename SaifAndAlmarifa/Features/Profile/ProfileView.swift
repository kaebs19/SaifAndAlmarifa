//
//  ProfileView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 13/04/2026.
//

import SwiftUI

// MARK: - شاشة الملف الشخصي
struct ProfileView: View {

    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var authManager = AuthManager.shared
    @State private var showLogoutAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSizes.Spacing.lg) {
                header
                avatarSection
                statsRow
                gameStatsSection
                friendCodeSection

                if viewModel.isEditing {
                    editForm
                }

                if !viewModel.avatars.isEmpty {
                    avatarGrid
                }

                actionsSection
            }
            .padding(AppSizes.Spacing.lg)
        }
        .background(GradientBackground.main)
        .alert("تسجيل الخروج", isPresented: $showLogoutAlert) {
            Button("خروج", role: .destructive) { viewModel.logout() }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("هل تريد تسجيل الخروج؟")
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - الهيدر مع زر عودة
    private var header: some View {
        ZStack {
            Text("الملف الشخصي")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)

            HStack {
                // زر التعديل
                if !viewModel.isEditing {
                    Button { viewModel.startEditing() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("تعديل")
                        }
                        .font(.cairo(.medium, size: AppSizes.Font.caption))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                    }
                }

                Spacer()

                // زر العودة
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - الأفاتار + الاسم
    private var avatarSection: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Button { viewModel.showAvatarPicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(imageURL: authManager.currentUser?.fullAvatarUrl, size: 90)
                        .overlay(Circle().stroke(tierColor, lineWidth: 3))
                        .shadow(color: tierColor.opacity(0.4), radius: 10)

                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                        .background(Circle().fill(Color(hex: "0E1236")).padding(2))
                        .offset(x: 4, y: 4)
                }
            }
            .sheet(isPresented: $viewModel.showAvatarPicker) {
                AvatarPickerSheet { _ in }
            }

            Text(authManager.currentUser?.username ?? "محارب")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)

            Text(tierName)
                .font(.cairo(.semiBold, size: AppSizes.Font.body))
                .foregroundStyle(tierColor)

            // شريط XP
            xpBar
        }
    }

    // MARK: شريط XP
    private var xpBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.1)).frame(height: 6)
                    Capsule().fill(tierColor).frame(width: geo.size.width * 0.35, height: 6)
                }
            }
            .frame(height: 6)
            .frame(maxWidth: 200)

            Text("\(AppStrings.Main.level) \(authManager.currentUser?.level ?? 1)")
                .font(.cairo(.medium, size: 10))
                .foregroundStyle(tierColor)
        }
    }

    // MARK: - الإحصائيات الأساسية
    private var statsRow: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            statCard(icon: "star.fill", value: "\(authManager.currentUser?.level ?? 1)", label: "المستوى", color: tierColor)
            statCard(icon: "diamond.fill", value: "\(authManager.currentUser?.gems ?? 0)", label: "الجواهر", color: AppColors.Default.goldPrimary)
            statCard(icon: "flag.fill", value: flagForCountry, label: "الدولة", color: AppColors.Default.info)
        }
    }

    // MARK: - إحصائيات اللعب
    private var gameStatsSection: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.sm) {
            Text("إحصائيات المعارك")
                .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(.white)

            HStack(spacing: AppSizes.Spacing.sm) {
                gameStatCard(value: "\(viewModel.totalMatches)", label: "مباريات", icon: "gamecontroller.fill", color: AppColors.Default.info)
                gameStatCard(value: "\(viewModel.totalWins)", label: "فوز", icon: "trophy.fill", color: AppColors.Default.goldPrimary)
                gameStatCard(value: "\(viewModel.totalLosses)", label: "خسارة", icon: "xmark.shield.fill", color: AppColors.Default.error)
                gameStatCard(value: viewModel.winRate, label: "نسبة الفوز", icon: "chart.line.uptrend.xyaxis", color: AppColors.Default.success)
            }
        }
    }

    private func gameStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: AppSizes.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.poppins(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(.white)
            Text(label)
                .font(.cairo(.regular, size: 9))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.small).stroke(color.opacity(0.12), lineWidth: 1))
    }

    // MARK: - كود الصداقة
    private var friendCodeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("كود الصداقة")
                    .font(.cairo(.medium, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.5))
                Text(authManager.currentUser?.friendCode ?? "------")
                    .font(.poppins(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .kerning(4)
            }
            Spacer()
            Button(action: viewModel.copyFriendCode) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.Default.goldPrimary.opacity(0.1))
                    .clipShape(Circle())
            }
            ShareLink(item: "أضفني في سيف المعرفة!\nكود الصداقة: \(authManager.currentUser?.friendCode ?? "")") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.Default.goldPrimary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(AppSizes.Spacing.md)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.medium).stroke(AppColors.Default.goldPrimary.opacity(0.15), lineWidth: 1))
    }

    // MARK: - نموذج التعديل
    private var editForm: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            AuthLabeledField(label: "اسم المستخدم") {
                AppTextField(placeholder: "اسم جديد", text: $viewModel.editUsername, icon: "person.fill", contentType: .username, style: .glass)
            }
            AuthLabeledField(label: "الدولة") {
                CountryPickerButton(selectedCountry: $viewModel.editCountry)
            }
            HStack(spacing: AppSizes.Spacing.md) {
                GradientButton(title: "حفظ", colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary], isLoading: viewModel.isLoading) {
                    Task { await viewModel.saveProfile() }
                }
                Button { viewModel.isEditing = false } label: {
                    Text("إلغاء").font(.cairo(.medium, size: AppSizes.Font.body)).foregroundStyle(.white.opacity(0.6)).frame(maxWidth: .infinity).frame(height: AppSizes.Button.large)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: 0.25), value: viewModel.isEditing)
    }

    // MARK: - شبكة الأفاتارات
    private var avatarGrid: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.sm) {
            Text("الصور الشخصية")
                .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSizes.Spacing.md), count: 5), spacing: AppSizes.Spacing.md) {
                ForEach(viewModel.avatars) { avatar in
                    Button { Task { await viewModel.selectAvatar(avatar) } } label: {
                        AsyncImage(url: URL(string: avatarFullUrl(avatar.imageUrl))) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(.white.opacity(0.1))
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                authManager.currentUser?.avatarUrl == avatar.imageUrl ? AppColors.Default.goldPrimary : .white.opacity(0.1),
                                lineWidth: 2
                            )
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if let cost = avatar.gemCost, cost > 0 {
                                HStack(spacing: 2) {
                                    Image("icon_gem").resizable().frame(width: 10, height: 10)
                                    Text("\(cost)").font(.system(size: 8, weight: .bold)).foregroundStyle(AppColors.Default.goldPrimary)
                                }
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Color(hex: "0E1236")).clipShape(Capsule()).offset(x: 2, y: 2)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - الإجراءات
    private var actionsSection: some View {
        VStack(spacing: 0) {
            actionRow(icon: "rectangle.portrait.and.arrow.right", title: "تسجيل الخروج", color: .red) {
                showLogoutAlert = true
            }
        }
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.medium).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func actionRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: icon).foregroundStyle(color).frame(width: 24)
                Text(title).font(.cairo(.medium, size: AppSizes.Font.body)).foregroundStyle(color)
                Spacer()
            }
            .padding(AppSizes.Spacing.md)
        }
    }

    // MARK: - Helpers

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSizes.Spacing.xs) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
            Text(value).font(.cairo(.bold, size: AppSizes.Font.title3)).foregroundStyle(.white)
            Text(label).font(.cairo(.regular, size: 10)).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.md)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.medium).stroke(color.opacity(0.15), lineWidth: 1))
    }

    private var tierColor: Color {
        let level = authManager.currentUser?.level ?? 1
        switch level {
        case 1...5: return AppColors.Tier.bronze
        case 6...15: return AppColors.Tier.silver
        case 16...30: return AppColors.Tier.gold
        case 31...50: return AppColors.Tier.platinum
        default: return AppColors.Tier.diamond
        }
    }

    private var tierName: String {
        let level = authManager.currentUser?.level ?? 1
        switch level {
        case 1...5: return "🥉 برونزي"
        case 6...15: return "🥈 فضي"
        case 16...30: return "🥇 ذهبي"
        case 31...50: return "💎 بلاتيني"
        default: return "👑 أسطوري"
        }
    }

    private var flagForCountry: String {
        CountryList.all.first { $0.id == authManager.currentUser?.country }?.flag ?? "🌍"
    }

    private func avatarFullUrl(_ path: String) -> String {
        path.hasPrefix("http") ? path : APIConfig.environment.baseURL.replacingOccurrences(of: "/api/v1", with: "") + path
    }
}
