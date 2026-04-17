//
//  ClansHubView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/ClansHubView.swift
//  الشاشة الرئيسية للعشائر
//  - إذا اللاعب عضو في عشيرة → بطاقة عشيرتي + زر الدخول
//  - إذا ما عنده عشيرة → زر إنشاء + بحث + ترتيب العشائر

import SwiftUI

struct ClansHubView: View {

    @StateObject private var viewModel = ClansHubViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateSheet = false
    @State private var navigateToClanId: String?

    var body: some View {
        VStack(spacing: 0) {
            ClanScreenHeader(title: "العشائر", onClose: { dismiss() })

            if let clan = viewModel.myClan {
                myClanCard(clan)
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.bottom, AppSizes.Spacing.md)
            } else if viewModel.hasLoaded {
                createBanner
                    .padding(.horizontal, AppSizes.Spacing.lg)
                    .padding(.bottom, AppSizes.Spacing.md)
            }

            ClanTabBar(tabs: ["الترتيب", "بحث"], selection: $viewModel.selectedTab)

            TabView(selection: $viewModel.selectedTab) {
                topClansList.tag(0)
                searchSection.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(GradientBackground.main)
        .withToast()
        .task { await viewModel.onAppear() }
        .refreshable { await viewModel.refresh() }
        .sheet(isPresented: $showCreateSheet) {
            CreateClanSheet { clan in
                viewModel.handleCreated(clan)
                navigateToClanId = clan.id
            }
        }
        .fullScreenCover(item: Binding(
            get: { navigateToClanId.map { IdentifiableString(value: $0) } },
            set: { navigateToClanId = $0?.value }
        )) { wrapper in
            ClanDetailView(clanId: wrapper.value) {
                navigateToClanId = nil
                Task { await viewModel.refresh() }
            }
        }
    }

    // MARK: - بطاقة عشيرتي
    private func myClanCard(_ clan: Clan) -> some View {
        Button {
            HapticManager.medium()
            navigateToClanId = clan.id
        } label: {
            HStack(spacing: AppSizes.Spacing.md) {
                ClanBadgeView(badge: clan.badge, color: clan.displayColor, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(clan.name)
                            .font(.cairo(.bold, size: AppSizes.Font.title3))
                            .foregroundStyle(.white)
                        if let role = clan.myRole {
                            Image(systemName: role.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(role.color)
                        }
                    }
                    HStack(spacing: 10) {
                        label(icon: "shield.lefthalf.filled", text: "Lv.\(clan.level)")
                        label(icon: "person.2.fill", text: "\(clan.memberCount ?? 0)")
                        label(icon: "chart.line.uptrend.xyaxis", text: "\(clan.weeklyPoints)")
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(AppSizes.Spacing.md)
            .background(
                LinearGradient(
                    colors: [clan.displayColor.opacity(0.18), clan.displayColor.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(clan.displayColor.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - بانر الإنشاء
    private var createBanner: some View {
        Button {
            HapticManager.medium()
            showCreateSheet = true
        } label: {
            HStack(spacing: AppSizes.Spacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("أنشئ عشيرتك الخاصة")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                    Text("تكلفة الإنشاء: 500 ذهب")
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(AppSizes.Spacing.md)
            .background(Color(hex: "12103B").opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(AppColors.Default.goldPrimary.opacity(0.25), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - قائمة الترتيب
    private var topClansList: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.topClans.isEmpty {
                SkeletonList(count: 8).padding(.top, AppSizes.Spacing.sm)
            } else if viewModel.topClans.isEmpty {
                ClanEmptyState(icon: "trophy", title: "لا توجد عشائر بعد")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.topClans) { entry in
                        ClanRankRow(entry: entry) {
                            navigateToClanId = entry.id
                        }
                        Divider().overlay(.white.opacity(0.05)).padding(.leading, 70)
                    }
                }
                .padding(.top, AppSizes.Spacing.sm)
            }
        }
    }

    // MARK: - البحث
    private var searchSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSizes.Spacing.sm) {
                AppTextField(
                    placeholder: "ابحث باسم العشيرة",
                    text: $viewModel.searchText,
                    icon: "magnifyingglass",
                    style: .glass
                )
                GradientButton(
                    title: "بحث",
                    colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary],
                    isEnabled: viewModel.searchText.count >= 2
                ) {
                    Task { await viewModel.search() }
                }
                .frame(width: 80)
            }
            .padding(AppSizes.Spacing.lg)

            ScrollView {
                if viewModel.isSearching {
                    SkeletonList(count: 5).padding(.top, AppSizes.Spacing.sm)
                } else if viewModel.searchResults.isEmpty {
                    ClanEmptyState(
                        icon: "magnifyingglass",
                        title: "ابحث عن عشيرة",
                        subtitle: "اكتب اسم العشيرة (حرفين على الأقل)"
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { entry in
                            ClanRankRow(entry: entry) {
                                navigateToClanId = entry.id
                            }
                            Divider().overlay(.white.opacity(0.05)).padding(.leading, 70)
                        }
                    }
                }
            }
        }
        .dismissKeyboardOnTap()
    }

    // MARK: - Helpers
    private func label(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.poppins(.semiBold, size: 11))
        }
    }
}

// MARK: - Helper (للـ fullScreenCover(item:))
struct IdentifiableString: Identifiable {
    var id: String { value }
    let value: String
}
