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
        ZStack {
            GradientBackground.main

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSizes.Spacing.lg) {
                    closeButton
                    profileCard
                    statsCard

                    if viewModel.isEditing { editForm }
                    if !viewModel.avatars.isEmpty { avatarGrid }

                    friendCodeSection
                    actionsSection
                }
                .padding(AppSizes.Spacing.lg)
                .padding(.bottom, AppSizes.Spacing.xxl)
            }
        }
        .alert("تسجيل الخروج", isPresented: $showLogoutAlert) {
            Button("خروج", role: .destructive) { viewModel.logout() }
            Button("إلغاء", role: .cancel) {}
        } message: { Text("هل تريد تسجيل الخروج؟") }
        .task { await viewModel.onAppear() }
    }

    // MARK: - زر الإغلاق
    private var closeButton: some View {
        HStack {
            if !viewModel.isEditing {
                Button { viewModel.startEditing() } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - ═══════ بطاقة الملف الشخصي ═══════

    private var profileCard: some View {
        VStack(spacing: 0) {
            // الجزء العلوي — الأفاتار + الاسم
            VStack(spacing: AppSizes.Spacing.md) {
                // الأفاتار
                Button { viewModel.showAvatarPicker = true } label: {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(imageURL: authManager.currentUser?.fullAvatarUrl, size: 90)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [tierColor, tierColor.opacity(0.5)],
                                            startPoint: .top, endPoint: .bottom
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: tierColor.opacity(0.5), radius: 12)

                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                            .background(Circle().fill(Color(hex: "0E1236")).padding(2))
                            .offset(x: 4, y: 4)
                    }
                }
                .sheet(isPresented: $viewModel.showAvatarPicker) {
                    AvatarPickerSheet { _ in }
                }

                // الاسم
                Text(authManager.currentUser?.username ?? "محارب")
                    .font(.cairo(.black, size: AppSizes.Font.title1))
                    .foregroundStyle(.white)

                // الدولة
                HStack(spacing: 6) {
                    Text(flagForCountry)
                        .font(.system(size: 20))
                    Text(countryName)
                        .font(.cairo(.medium, size: AppSizes.Font.body))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.xl)
            .background(
                LinearGradient(
                    colors: [tierColor.opacity(0.15), Color(hex: "12103B")],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // الجزء السفلي — الرتبة + المعلومات
            VStack(spacing: AppSizes.Spacing.md) {
                // الرتبة + كود الصداقة
                HStack {
                    // كود الصداقة
                    VStack(alignment: .leading, spacing: 2) {
                        Text("كود الصداقة")
                            .font(.cairo(.regular, size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(authManager.currentUser?.friendCode ?? "------")
                            .font(.poppins(.bold, size: AppSizes.Font.bodyLarge))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                    }

                    Spacer()

                    // الرتبة
                    HStack(spacing: 6) {
                        Text(tierEmoji)
                            .font(.system(size: 20))
                        Text(tierLabel)
                            .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                            .foregroundStyle(tierColor)
                    }
                }

                Divider().overlay(.white.opacity(0.08))

                // المستوى + الجواهر
                HStack(spacing: AppSizes.Spacing.xl) {
                    infoItem(icon: "star.fill", value: "\(authManager.currentUser?.level ?? 1)", label: "المستوى", color: tierColor)
                    infoItem(icon: "diamond.fill", value: "\(authManager.currentUser?.gems ?? 0)", label: "الجواهر", color: AppColors.Default.goldPrimary)

                    // شريط XP
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.1)).frame(height: 5)
                                Capsule().fill(tierColor).frame(width: geo.size.width * 0.35, height: 5)
                            }
                        }
                        .frame(height: 5)
                        Text("XP")
                            .font(.cairo(.medium, size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(AppSizes.Spacing.md)
            .background(Color(hex: "12103B"))
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                .stroke(tierColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: tierColor.opacity(0.15), radius: 15, y: 5)
    }

    // MARK: - ═══════ بطاقة الإحصائيات ═══════

    private var statsCard: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // العنوان
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppColors.Default.goldPrimary)
                Text("الإحصائيات")
                    .font(.cairo(.bold, size: AppSizes.Font.bodyLarge))
                    .foregroundStyle(.white)
                Spacer()
            }

            // الصف الأول
            HStack(spacing: AppSizes.Spacing.sm) {
                statItem(
                    label: "مرات الفوز",
                    value: "\(viewModel.stats?.wins ?? 0) / \(viewModel.stats?.totalMatches ?? 0)",
                    color: AppColors.Default.goldPrimary
                )
                statItem(
                    label: "معدل الفوز",
                    value: "\(viewModel.stats?.winRate ?? 0)%",
                    color: AppColors.Default.success
                )
            }

            // الصف الثاني
            HStack(spacing: AppSizes.Spacing.sm) {
                statItem(
                    label: "مكاسب متتابعة",
                    value: "\(viewModel.stats?.currentStreak ?? 0)",
                    color: AppColors.Default.warning
                )
                statItem(
                    label: "إجابات صحيحة",
                    value: "\(viewModel.stats?.totalCorrectAnswers ?? 0)",
                    color: AppColors.Default.info
                )
            }

            // الصف الثالث
            HStack(spacing: AppSizes.Spacing.sm) {
                statItem(
                    label: "فوز 1v1",
                    value: "\(viewModel.stats?.wins1v1 ?? 0)",
                    color: AppColors.Default.goldPrimary
                )
                statItem(
                    label: "فوز 4 لاعبين",
                    value: "\(viewModel.stats?.wins4player ?? 0)",
                    color: AppColors.Default.error
                )
            }

            // عدد القتل
            HStack(spacing: AppSizes.Spacing.sm) {
                statItem(
                    label: "عدد القتل",
                    value: "\(viewModel.stats?.totalKills ?? 0)",
                    color: .red
                )
                statItem(
                    label: "إجمالي المباريات",
                    value: "\(viewModel.stats?.totalMatches ?? 0)",
                    color: .white.opacity(0.6)
                )
            }
        }
        .padding(AppSizes.Spacing.md)
        .background(Color(hex: "12103B"))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: خلية إحصائية
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.cairo(.regular, size: 10))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.poppins(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small))
    }

    // MARK: - ═══════ كود الصداقة ═══════

    private var friendCodeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("شارك كود الصداقة")
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
        .background(Color(hex: "12103B"))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.medium).stroke(AppColors.Default.goldPrimary.opacity(0.15), lineWidth: 1))
    }

    // MARK: - ═══════ نموذج التعديل ═══════

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
        .padding(AppSizes.Spacing.md)
        .background(Color(hex: "12103B"))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.large).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - ═══════ شبكة الأفاتارات ═══════

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
                                }.padding(.horizontal, 4).padding(.vertical, 1).background(Color(hex: "0E1236")).clipShape(Capsule()).offset(x: 2, y: 2)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - ═══════ الإجراءات ═══════

    private var actionsSection: some View {
        Button { showLogoutAlert = true } label: {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: "rectangle.portrait.and.arrow.right").foregroundStyle(.red)
                Text("تسجيل الخروج").font(.cairo(.semiBold, size: AppSizes.Font.body)).foregroundStyle(.red)
                Spacer()
            }
            .padding(AppSizes.Spacing.md)
            .background(.red.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.medium).stroke(.red.opacity(0.15), lineWidth: 1))
        }
    }

    // MARK: - ═══════ Helpers ═══════

    private func infoItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
            Text(value).font(.poppins(.bold, size: AppSizes.Font.body)).foregroundStyle(.white)
            Text(label).font(.cairo(.regular, size: 9)).foregroundStyle(.white.opacity(0.4))
        }
    }

    private var tierColor: Color {
        let l = authManager.currentUser?.level ?? 1
        switch l { case 1...5: return AppColors.Tier.bronze; case 6...15: return AppColors.Tier.silver; case 16...30: return AppColors.Tier.gold; case 31...50: return AppColors.Tier.platinum; default: return AppColors.Tier.diamond }
    }

    private var tierLabel: String {
        let l = authManager.currentUser?.level ?? 1
        switch l { case 1...5: return "برونزي"; case 6...15: return "فضي"; case 16...30: return "ذهبي"; case 31...50: return "بلاتيني"; default: return "أسطوري" }
    }

    private var tierEmoji: String {
        let l = authManager.currentUser?.level ?? 1
        switch l { case 1...5: return "🥉"; case 6...15: return "🥈"; case 16...30: return "🥇"; case 31...50: return "💎"; default: return "👑" }
    }

    private var flagForCountry: String {
        CountryList.all.first { $0.id == authManager.currentUser?.country }?.flag ?? "🌍"
    }

    private var countryName: String {
        CountryList.all.first { $0.id == authManager.currentUser?.country }?.nameAr ?? "غير محدد"
    }

    private func avatarFullUrl(_ path: String) -> String {
        path.hasPrefix("http") ? path : APIConfig.environment.baseURL.replacingOccurrences(of: "/api/v1", with: "") + path
    }
}

#Preview {
    ProfileView()
        .environment(\.layoutDirection, .rightToLeft)
}
