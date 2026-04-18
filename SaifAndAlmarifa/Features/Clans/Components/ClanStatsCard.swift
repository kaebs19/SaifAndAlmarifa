//
//  ClanStatsCard.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/Components/ClanStatsCard.swift
//  بطاقات إحصائيات + منصّة Top 3 + كارت عشيرتي الكبير

import SwiftUI

// MARK: - بطاقة إحصاء واحدة
struct ClanStatTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            Text(value)
                .font(.poppins(.bold, size: 16))
                .foregroundStyle(.white)
            Text(label)
                .font(.cairo(.medium, size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.md)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - شريط تقدّم للمستوى
struct ClanProgressBar: View {
    let current: Int
    let max: Int
    let color: Color

    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(1.0, Double(current) / Double(max))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(current)")
                    .font(.poppins(.bold, size: 12))
                    .foregroundStyle(color)
                Spacer()
                Text("/ \(max)")
                    .font(.poppins(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(colors: [color.opacity(0.7), color],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * progress)
                        .shadow(color: color.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - منصّة Top 3
struct ClanPodium: View {
    let top3: [ClanRankEntry]
    var onTap: (ClanRankEntry) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSizes.Spacing.sm) {
            if top3.count > 1 { podiumItem(top3[1], rank: 2, height: 110) }
            if let first = top3.first { podiumItem(first, rank: 1, height: 140) }
            if top3.count > 2 { podiumItem(top3[2], rank: 3, height: 90) }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, AppSizes.Spacing.md)
    }

    private func podiumItem(_ entry: ClanRankEntry, rank: Int, height: CGFloat) -> some View {
        let rankColor: Color = {
            switch rank {
            case 1: return Color(hex: "FFD700")
            case 2: return Color(hex: "C0C0C0")
            default: return Color(hex: "CD7F32")
            }
        }()
        let emoji: String = {
            switch rank {
            case 1: return "🥇"
            case 2: return "🥈"
            default: return "🥉"
            }
        }()

        return Button {
            HapticManager.light()
            onTap(entry)
        } label: {
            VStack(spacing: 6) {
                ClanBadgeView(badge: entry.badge, color: entry.displayColor, size: rank == 1 ? 56 : 44)
                Text(emoji).font(.system(size: rank == 1 ? 22 : 18))
                Text(entry.name)
                    .font(.cairo(.bold, size: rank == 1 ? 12 : 11))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(entry.weeklyPoints)")
                    .font(.poppins(.bold, size: rank == 1 ? 13 : 11))
                    .foregroundStyle(rankColor)
                Spacer(minLength: 4)
                // قاعدة المنصّة
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [rankColor.opacity(0.4), rankColor.opacity(0.15)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: height * 0.45)
                    .overlay(
                        Text("\(rank)")
                            .font(.poppins(.black, size: rank == 1 ? 32 : 24))
                            .foregroundStyle(rankColor.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(rankColor.opacity(0.4), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - كارت عشيرتي الكبير (Hero)
struct MyClanHeroCard: View {
    let clan: Clan
    var onTap: () -> Void

    var body: some View {
        Button(action: { HapticManager.medium(); onTap() }) {
            VStack(spacing: AppSizes.Spacing.md) {
                // صف علوي
                HStack(spacing: AppSizes.Spacing.md) {
                    ClanBadgeView(badge: clan.badge, color: clan.displayColor, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(clan.name)
                                .font(.cairo(.bold, size: AppSizes.Font.title3))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            if let role = clan.myRole {
                                Image(systemName: role.icon)
                                    .font(.system(size: 12))
                                    .foregroundStyle(role.color)
                            }
                        }
                        HStack(spacing: 8) {
                            Text("Lv.\(clan.level)")
                                .font(.poppins(.bold, size: 10))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(clan.displayColor)
                                .clipShape(Capsule())
                            Text("\(clan.memberCount ?? 0)/\(clan.maxMembers ?? 30) عضو")
                                .font(.cairo(.medium, size: 11))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // شريط تقدّم المستوى
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("نقاط هذا الأسبوع")
                            .font(.cairo(.medium, size: 10))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Text("\(clan.weeklyPoints)")
                            .font(.poppins(.bold, size: 13))
                            .foregroundStyle(clan.displayColor)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(colors: [clan.displayColor.opacity(0.6), clan.displayColor],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * clan.levelProgress)
                                .shadow(color: clan.displayColor.opacity(0.6), radius: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(AppSizes.Spacing.md)
            .background(
                LinearGradient(
                    colors: [clan.displayColor.opacity(0.22), clan.displayColor.opacity(0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [clan.displayColor.opacity(0.5), clan.displayColor.opacity(0.15)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: clan.displayColor.opacity(0.15), radius: 15, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
