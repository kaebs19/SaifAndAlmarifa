//
//  MatchHistoryView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/MatchHistory/MatchHistoryView.swift
//  تاريخ المباريات

import SwiftUI
import Combine

@MainActor
final class MatchHistoryViewModel: ObservableObject {
    @Published var items: [MatchHistoryItem] = []
    @Published var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = (try? await NetworkManager.shared.request(MatchHistoryEndpoint.List())) ?? []
    }

    var wins: Int { items.filter(\.didIWin).count }
    var losses: Int { items.count - wins }
    var winRate: Int {
        guard !items.isEmpty else { return 0 }
        return Int(Double(wins) / Double(items.count) * 100)
    }
}

struct MatchHistoryView: View {

    @StateObject private var viewModel = MatchHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            if !viewModel.items.isEmpty {
                statsCards
            }
            content
        }
        .background(GradientBackground.main)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Header
    private var header: some View {
        ZStack {
            Text("تاريخ المباريات")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(.white)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            }
        }
        .padding(AppSizes.Spacing.lg)
    }

    // MARK: - Stats
    private var statsCards: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            statCard(label: "إجمالي", value: "\(viewModel.items.count)", color: AppColors.Default.goldPrimary)
            statCard(label: "فوز", value: "\(viewModel.wins)", color: AppColors.Default.success)
            statCard(label: "خسارة", value: "\(viewModel.losses)", color: AppColors.Default.error)
            statCard(label: "نسبة الفوز", value: "\(viewModel.winRate)%", color: Color(hex: "60A5FA"))
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.bottom, AppSizes.Spacing.sm)
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.poppins(.black, size: 18))
                .foregroundStyle(color)
            Text(label)
                .font(.cairo(.medium, size: 9))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            SkeletonList(count: 8)
                .padding(.top, AppSizes.Spacing.sm)
        } else if viewModel.items.isEmpty {
            VStack(spacing: AppSizes.Spacing.md) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.2))
                Text("لا مباريات بعد")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.5))
                Text("العب أول مباراة لترى تاريخك هنا")
                    .font(.cairo(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.items) { item in
                        historyRow(item)
                    }
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.vertical, AppSizes.Spacing.sm)
            }
        }
    }

    // MARK: - Row
    private func historyRow(_ item: MatchHistoryItem) -> some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            // نتيجة
            ZStack {
                Circle()
                    .fill((item.didIWin ? AppColors.Default.success : AppColors.Default.error).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: item.didIWin ? "trophy.fill" : "flag.slash")
                    .font(.system(size: 18))
                    .foregroundStyle(item.didIWin ? AppColors.Default.success : AppColors.Default.error)
            }

            // التفاصيل
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.didIWin ? "فوز" : "خسارة")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(item.didIWin ? AppColors.Default.success : AppColors.Default.error)
                    Text("ضد")
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(item.opponentName ?? "—")
                        .font(.cairo(.semiBold, size: 11))
                        .foregroundStyle(.white)
                }
                HStack(spacing: 8) {
                    Text("\(item.myScore) - \(item.opponentScore)")
                        .font(.poppins(.semiBold, size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    if item.goldEarned > 0 {
                        Text("•").foregroundStyle(.white.opacity(0.2))
                        Text("+\(item.goldEarned) 🪙")
                            .font(.poppins(.medium, size: 10))
                            .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.8))
                    }
                    if let date = item.date {
                        Text("•").foregroundStyle(.white.opacity(0.2))
                        Text(relative(from: date))
                            .font(.cairo(.regular, size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            Spacer()
            Text(item.mode)
                .font(.poppins(.medium, size: 10))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .padding(AppSizes.Spacing.sm)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
    }

    private func relative(from date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ar")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
