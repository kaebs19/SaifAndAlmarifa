//
//  StoreView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import SwiftUI

struct StoreView: View {
    @StateObject private var viewModel = StoreViewModel()
    @State private var showGemStore = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            currencyBar
            buyGemsButton
            tabs
            TabView(selection: $viewModel.selectedTab) {
                shopGrid.tag(0)
                inventoryList.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(GradientBackground.main)
        .task { await viewModel.onAppear() }
    }

    // MARK: الهيدر
    private var header: some View {
        ZStack {
            Text("المتجر")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(AppSizes.Spacing.lg)
    }

    // MARK: شريط العملات
    private var currencyBar: some View {
        HStack(spacing: AppSizes.Spacing.lg) {
            currencyBadge(icon: "🪙", value: viewModel.userGold, label: "ذهب", color: Color(hex: "FFD700"))
            currencyBadge(icon: "💎", value: viewModel.userGems, label: "جواهر", color: Color(hex: "60A5FA"))
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.bottom, AppSizes.Spacing.md)
    }

    // MARK: زر شراء جواهر
    private var buyGemsButton: some View {
        Button { showGemStore = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("شراء جواهر")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppSizes.Button.medium)
            .background(
                LinearGradient(
                    colors: [Color(hex: "3B82F6"), Color(hex: "60A5FA")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.bottom, AppSizes.Spacing.sm)
        .fullScreenCover(isPresented: $showGemStore) { GemStoreView() }
    }

    private func currencyBadge(icon: String, value: Int, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(icon).font(.system(size: 18))
            Text("\(value)")
                .font(.poppins(.bold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(color)
            Text(label)
                .font(.cairo(.medium, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.medium).stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: التابات
    private var tabs: some View {
        HStack(spacing: 0) {
            tabBtn("الأدوات", tag: 0)
            tabBtn("المخزون (\(viewModel.inventory.count))", tag: 1)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    private func tabBtn(_ title: String, tag: Int) -> some View {
        Button { withAnimation { viewModel.selectedTab = tag }; HapticManager.selection() } label: {
            VStack(spacing: 4) {
                Text(title).font(.cairo(.semiBold, size: AppSizes.Font.body))
                    .foregroundStyle(viewModel.selectedTab == tag ? AppColors.Default.goldPrimary : .white.opacity(0.4))
                Capsule().fill(viewModel.selectedTab == tag ? AppColors.Default.goldPrimary : .clear).frame(height: 2)
            }.frame(maxWidth: .infinity)
        }
    }

    // MARK: شبكة المتجر
    private var shopGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: AppSizes.Spacing.md), GridItem(.flexible(), spacing: AppSizes.Spacing.md)],
                spacing: AppSizes.Spacing.md
            ) {
                ForEach(viewModel.items) { item in
                    itemCard(item)
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
    }

    // MARK: بطاقة عنصر
    private func itemCard(_ item: StoreItem) -> some View {
        let owned = viewModel.quantityOf(item.type)
        let canBuy = viewModel.userGold >= item.goldCost

        return VStack(spacing: AppSizes.Spacing.sm) {
            // الأيقونة
            Image(systemName: item.icon)
                .font(.system(size: 28))
                .foregroundStyle(item.color)
                .frame(width: 52, height: 52)
                .background(item.color.opacity(0.12))
                .clipShape(Circle())

            // الاسم
            Text(item.nameAr)
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
                .lineLimit(1)

            // الوصف
            Text(item.descriptionAr)
                .font(.cairo(.regular, size: 9))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // الكمية المملوكة
            if owned > 0 {
                Text("لديك: \(owned)")
                    .font(.cairo(.medium, size: 10))
                    .foregroundStyle(AppColors.Default.success)
            }

            // زر الشراء
            Button {
                Task { await viewModel.buy(item) }
            } label: {
                HStack(spacing: 4) {
                    Text("🪙").font(.system(size: 12))
                    Text("\(item.goldCost)")
                        .font(.poppins(.bold, size: AppSizes.Font.caption))
                        .foregroundStyle(canBuy ? Color(hex: "FFD700") : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(canBuy ? Color(hex: "FFD700").opacity(0.12) : .white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSizes.Radius.small)
                        .stroke(canBuy ? Color(hex: "FFD700").opacity(0.3) : .white.opacity(0.08), lineWidth: 1)
                )
            }
            .disabled(!canBuy || viewModel.isLoading)
        }
        .padding(AppSizes.Spacing.md)
        .background(.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(item.color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: قائمة المخزون
    private var inventoryList: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.inventory.isEmpty {
                VStack(spacing: AppSizes.Spacing.lg) {
                    Spacer(minLength: 80)
                    Image(systemName: "bag").font(.system(size: 50)).foregroundStyle(.white.opacity(0.2))
                    Text("المخزون فارغ").font(.cairo(.medium, size: AppSizes.Font.body)).foregroundStyle(.white.opacity(0.4))
                    Text("اشترِ أدوات من المتجر!").font(.cairo(.regular, size: AppSizes.Font.caption)).foregroundStyle(.white.opacity(0.3))
                }.frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.inventory) { inv in
                        let item = viewModel.items.first { $0.type == inv.itemType }
                        HStack(spacing: AppSizes.Spacing.md) {
                            Image(systemName: item?.icon ?? "questionmark.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(item?.color ?? .gray)
                                .frame(width: 40, height: 40)
                                .background((item?.color ?? .gray).opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item?.nameAr ?? inv.itemType)
                                    .font(.cairo(.bold, size: AppSizes.Font.body))
                                    .foregroundStyle(.white)
                                Text(item?.descriptionAr ?? "")
                                    .font(.cairo(.regular, size: 10))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("×\(inv.quantity)")
                                .font(.poppins(.bold, size: AppSizes.Font.title3))
                                .foregroundStyle(AppColors.Default.goldPrimary)
                        }
                        .padding(.horizontal, AppSizes.Spacing.lg)
                        .padding(.vertical, AppSizes.Spacing.sm)
                        Divider().overlay(.white.opacity(0.06))
                    }
                }
            }
        }
    }
}
