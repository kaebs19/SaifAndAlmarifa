//
//  FriendsView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            tabs
            TabView(selection: $viewModel.selectedTab) {
                friendsList.tag(0)
                requestsList.tag(1)
                searchSection.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(GradientBackground.main)
        .task { await viewModel.onAppear() }
    }

    // MARK: الهيدر
    private var header: some View {
        ZStack {
            Text("الأصدقاء").font(.cairo(.bold, size: AppSizes.Font.title2)).foregroundStyle(.white)
            HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundStyle(.white.opacity(0.4)) } }
        }.padding(AppSizes.Spacing.lg)
    }

    // MARK: التابات
    private var tabs: some View {
        HStack(spacing: 0) {
            tabButton("أصدقائي", count: viewModel.friends.count, tag: 0)
            tabButton("الطلبات", count: viewModel.requests.count, tag: 1)
            tabButton("بحث / إضافة", count: nil, tag: 2)
        }.padding(.horizontal, AppSizes.Spacing.lg)
    }

    private func tabButton(_ title: String, count: Int?, tag: Int) -> some View {
        Button { withAnimation { viewModel.selectedTab = tag }; HapticManager.selection() } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(title).font(.cairo(.semiBold, size: AppSizes.Font.caption))
                    if let c = count, c > 0 {
                        Text("\(c)").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16).background(AppColors.Default.error).clipShape(Circle())
                    }
                }
                .foregroundStyle(viewModel.selectedTab == tag ? AppColors.Default.goldPrimary : .white.opacity(0.4))
                Capsule().fill(viewModel.selectedTab == tag ? AppColors.Default.goldPrimary : .clear).frame(height: 2)
            }.frame(maxWidth: .infinity)
        }
    }

    // MARK: قائمة الأصدقاء
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.friends) { friend in
                    HStack(spacing: AppSizes.Spacing.sm) {
                        AvatarView(imageURL: friend.avatarUrl, size: 44, showOnlineIndicator: true, isOnline: friend.isOnline ?? false)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(friend.username).font(.cairo(.bold, size: AppSizes.Font.body)).foregroundStyle(.white)
                            Text("\(AppStrings.Main.level) \(friend.level ?? 1)").font(.cairo(.regular, size: 10)).foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        if friend.isOnline == true {
                            Text("متصل").font(.cairo(.medium, size: 10)).foregroundStyle(AppColors.Default.success)
                        }
                    }
                    .padding(.horizontal, AppSizes.Spacing.lg).padding(.vertical, AppSizes.Spacing.sm)
                    .swipeActions(edge: .leading) {
                        Button(role: .destructive) { Task { await viewModel.remove(friend) } } label: { Label("إزالة", systemImage: "trash") }
                    }
                    Divider().overlay(.white.opacity(0.06)).padding(.leading, 70)
                }
            }
            .padding(.top, AppSizes.Spacing.sm)

            if viewModel.friends.isEmpty {
                emptyState("لا يوجد أصدقاء بعد", icon: "person.2.slash")
            }
        }
    }

    // MARK: طلبات الصداقة
    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.requests) { req in
                    HStack(spacing: AppSizes.Spacing.sm) {
                        AvatarView(imageURL: req.avatarUrl, size: 44)
                        Text(req.username).font(.cairo(.bold, size: AppSizes.Font.body)).foregroundStyle(.white)
                        Spacer()
                        Button { Task { await viewModel.accept(req) } } label: {
                            Text("قبول").font(.cairo(.semiBold, size: 11)).foregroundStyle(.white)
                                .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 4)
                                .background(AppColors.Default.success).clipShape(Capsule())
                        }
                        Button { Task { await viewModel.reject(req) } } label: {
                            Text("رفض").font(.cairo(.semiBold, size: 11)).foregroundStyle(.red)
                                .padding(.horizontal, AppSizes.Spacing.sm).padding(.vertical, 4)
                                .overlay(Capsule().stroke(.red.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, AppSizes.Spacing.lg).padding(.vertical, AppSizes.Spacing.sm)
                    Divider().overlay(.white.opacity(0.06)).padding(.leading, 70)
                }
            }
            if viewModel.requests.isEmpty { emptyState("لا توجد طلبات", icon: "tray") }
        }
    }

    // MARK: بحث + إضافة بكود
    private var searchSection: some View {
        ScrollView {
            VStack(spacing: AppSizes.Spacing.lg) {
                // إضافة بكود
                VStack(alignment: .leading, spacing: AppSizes.Spacing.sm) {
                    Text("إضافة بكود الصداقة").font(.cairo(.bold, size: AppSizes.Font.body)).foregroundStyle(.white)
                    HStack {
                        AppTextField(placeholder: "أدخل الكود", text: $viewModel.friendCodeText, icon: "number", keyboardType: .numberPad, contentType: .oneTimeCode, style: .glass)
                        GradientButton(title: "أضف", colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary], isEnabled: !viewModel.friendCodeText.isEmpty) {
                            Task { await viewModel.addByCode() }
                        }.frame(width: 80)
                    }
                }

                // بحث بالاسم
                VStack(alignment: .leading, spacing: AppSizes.Spacing.sm) {
                    Text("بحث عن لاعب").font(.cairo(.bold, size: AppSizes.Font.body)).foregroundStyle(.white)
                    HStack {
                        AppTextField(placeholder: "اسم المستخدم", text: $viewModel.searchText, icon: "magnifyingglass", style: .glass)
                        GradientButton(title: "بحث", colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary], isEnabled: viewModel.searchText.count >= 2) {
                            Task { await viewModel.search() }
                        }.frame(width: 80)
                    }
                }

                // نتائج البحث
                ForEach(viewModel.searchResults) { user in
                    HStack(spacing: AppSizes.Spacing.sm) {
                        AvatarView(imageURL: user.avatarUrl, size: 40)
                        VStack(alignment: .leading) {
                            Text(user.username).font(.cairo(.bold, size: AppSizes.Font.body)).foregroundStyle(.white)
                            Text("\(AppStrings.Main.level) \(user.level ?? 1)").font(.cairo(.regular, size: 10)).foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        Button { Task { await viewModel.sendRequest(to: user.id) } } label: {
                            Image(systemName: "person.badge.plus").foregroundStyle(AppColors.Default.goldPrimary)
                        }
                    }
                    .padding(.vertical, AppSizes.Spacing.xs)
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
        .dismissKeyboardOnTap()
    }

    private func emptyState(_ text: String, icon: String) -> some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Spacer(minLength: 60)
            Image(systemName: icon).font(.system(size: 40)).foregroundStyle(.white.opacity(0.2))
            Text(text).font(.cairo(.medium, size: AppSizes.Font.body)).foregroundStyle(.white.opacity(0.4))
        }.frame(maxWidth: .infinity)
    }
}
