//
//  LeaderboardView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import SwiftUI

struct LeaderboardView: View {
    @State private var selectedType: LeaderboardType = .allTime
    @State private var players: [LeaderboardPlayer] = []
    @State private var myRank: Int?
    @State private var isLoading = true
    @State private var showPlayerCard = false
    @State private var selectedPlayer: LeaderboardPlayer?
    @Environment(\.dismiss) private var dismiss
    private let network: NetworkClient = NetworkManager.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            typeTabs
            if isLoading {
                Spacer()
                ProgressView().tint(AppColors.Default.goldPrimary)
                Spacer()
            } else {
                leaderboardList
            }
        }
        .background(GradientBackground.main)
        .task { await load() }
        .onChange(of: selectedType) { _, _ in Task { await load() } }
        .playerCard(
            isPresented: $showPlayerCard,
            data: selectedPlayer.map {
                PlayerCardData(username: $0.username, avatarUrl: $0.fullAvatarUrl,
                               country: $0.country, level: $0.level ?? 1,
                               gems: 0, friendCode: nil, stats: nil)
            }
        )
    }

    // MARK: الهيدر
    private var header: some View {
        ZStack {
            Text("المتصدرين 🏆")
                .font(.cairo(.bold, size: AppSizes.Font.title2))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(AppSizes.Spacing.lg)
    }

    // MARK: التابات
    private var typeTabs: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardType.allCases, id: \.self) { type in
                Button {
                    withAnimation { selectedType = type }
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 4) {
                        Text(type.title)
                            .font(.cairo(.semiBold, size: AppSizes.Font.body))
                            .foregroundStyle(selectedType == type ? AppColors.Default.goldPrimary : .white.opacity(0.4))
                        Capsule()
                            .fill(selectedType == type ? AppColors.Default.goldPrimary : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
    }

    // MARK: القائمة
    private var leaderboardList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // أعلى 3
                if players.count >= 3 {
                    topThree
                }

                // الباقي
                ForEach(Array(players.dropFirst(min(3, players.count)))) { player in
                    playerRow(player)
                    Divider().overlay(.white.opacity(0.04))
                }

                // ترتيبي
                if let rank = myRank {
                    HStack {
                        Spacer()
                        Text("ترتيبك: #\(rank)")
                            .font(.cairo(.bold, size: AppSizes.Font.body))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                        Spacer()
                    }
                    .padding(AppSizes.Spacing.md)
                    .background(AppColors.Default.goldPrimary.opacity(0.06))
                }
            }
        }
    }

    // MARK: أعلى 3
    private var topThree: some View {
        HStack(alignment: .bottom, spacing: AppSizes.Spacing.md) {
            if players.count > 1 { podiumCard(players[1], rank: 2, height: 90) }
            if players.count > 0 { podiumCard(players[0], rank: 1, height: 110) }
            if players.count > 2 { podiumCard(players[2], rank: 3, height: 75) }
        }
        .padding(AppSizes.Spacing.lg)
    }

    private func podiumCard(_ player: LeaderboardPlayer, rank: Int, height: CGFloat) -> some View {
        let medals = ["🥇", "🥈", "🥉"]
        return Button {
            selectedPlayer = player
            showPlayerCard = true
        } label: {
            VStack(spacing: AppSizes.Spacing.xs) {
                Text(medals[rank - 1]).font(.system(size: rank == 1 ? 28 : 22))

                AsyncImage(url: URL(string: player.fullAvatarUrl ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill").font(.system(size: 18)).foregroundStyle(.gray)
                }
                .frame(width: rank == 1 ? 56 : 44, height: rank == 1 ? 56 : 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(rank == 1 ? Color(hex: "FFD700") : .white.opacity(0.2), lineWidth: 2))

                Text(player.username)
                    .font(.cairo(.bold, size: rank == 1 ? 13 : 11))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(player.totalPoints ?? 0)")
                    .font(.poppins(.bold, size: 11))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(rank == 1 ? Color(hex: "FFD700").opacity(0.3) : .white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // MARK: صف لاعب
    private func playerRow(_ player: LeaderboardPlayer) -> some View {
        Button {
            selectedPlayer = player
            showPlayerCard = true
        } label: {
            HStack(spacing: AppSizes.Spacing.sm) {
                Text("#\(player.rank)")
                    .font(.poppins(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 32)

                AsyncImage(url: URL(string: player.fullAvatarUrl ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(.white.opacity(0.1))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())

                Text(player.username)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let country = player.country, let flag = CountryList.all.first(where: { $0.id == country })?.flag {
                    Text(flag).font(.system(size: 14))
                }

                Spacer()

                Text("\(player.totalPoints ?? 0)")
                    .font(.poppins(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.vertical, AppSizes.Spacing.sm)
        }
    }

    // MARK: - تحميل
    private func load() async {
        isLoading = true; defer { isLoading = false }
        let response = try? await network.request(LeaderboardEndpoint.Get(type: selectedType))
        players = response?.players ?? []
        myRank = response?.myRank
    }
}
