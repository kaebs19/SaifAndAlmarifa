//
//  ClanExtrasTabs.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/ClanExtrasTabs.swift
//  Tabs إضافية: السجل، الخزينة، الامتيازات، الحرب

import SwiftUI

// MARK: - History Feed Tab
struct ClanHistoryTab: View {
    let events: [ClanEvent]
    let isLoading: Bool

    var body: some View {
        ScrollView {
            if isLoading && events.isEmpty {
                SkeletonList(count: 6).padding(.top, AppSizes.Spacing.sm)
            } else if events.isEmpty {
                ClanEmptyState(icon: "clock.arrow.circlepath", title: "لا أحداث بعد")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(events) { event in
                        eventRow(event)
                        Divider().overlay(.white.opacity(0.05)).padding(.leading, 60)
                    }
                }
                .padding(.top, AppSizes.Spacing.sm)
            }
        }
    }

    private func eventRow(_ event: ClanEvent) -> some View {
        HStack(alignment: .top, spacing: AppSizes.Spacing.sm) {
            // أيقونة + أفاتار
            ZStack(alignment: .bottomTrailing) {
                AvatarView(imageURL: event.actor?.avatarUrl, size: 40)
                Image(systemName: event.icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(AppColors.Default.goldPrimary)
                    .clipShape(Circle())
                    .offset(x: 3, y: 3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.arabicDescription)
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if let date = event.date {
                    Text(relativeTime(from: date))
                        .font(.cairo(.regular, size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, AppSizes.Spacing.sm)
    }

    private func relativeTime(from date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ar")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Perks Tab
struct ClanPerksTab: View {
    let clanLevel: Int

    var body: some View {
        ScrollView {
            VStack(spacing: AppSizes.Spacing.md) {
                Text("امتيازات المستوى \(clanLevel)")
                    .font(.cairo(.bold, size: AppSizes.Font.title3))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVStack(spacing: AppSizes.Spacing.sm) {
                    ForEach(ClanPerk.allCases) { perk in
                        perkRow(perk)
                    }
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
    }

    private func perkRow(_ perk: ClanPerk) -> some View {
        let unlocked = perk.isUnlocked(for: clanLevel)
        return HStack(spacing: AppSizes.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(unlocked ? perk.color.opacity(0.2) : Color.white.opacity(0.04))
                    .frame(width: 44, height: 44)
                Image(systemName: unlocked ? perk.icon : "lock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(unlocked ? perk.color : .white.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(perk.title)
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(unlocked ? .white : .white.opacity(0.5))
                    if !unlocked {
                        Text("Lv.\(perk.unlockLevel)")
                            .font(.poppins(.bold, size: 9))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(AppColors.Default.warning)
                            .clipShape(Capsule())
                    }
                }
                Text(perk.description)
                    .font(.cairo(.regular, size: 11))
                    .foregroundStyle(.white.opacity(unlocked ? 0.6 : 0.3))
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.Default.success)
            }
        }
        .padding(AppSizes.Spacing.sm)
        .background(unlocked ? perk.color.opacity(0.05) : .white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(
                    unlocked ? perk.color.opacity(0.25) : .white.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Treasury Tab
struct ClanTreasuryTab: View {
    let treasury: Int
    let history: [TreasuryTransaction]
    let myGold: Int
    var onDonate: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSizes.Spacing.md) {
                treasuryHeader
                donateButton

                if !history.isEmpty {
                    HStack {
                        Text("آخر التبرّعات")
                            .font(.cairo(.bold, size: AppSizes.Font.caption))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                    }
                    .padding(.top, AppSizes.Spacing.sm)

                    LazyVStack(spacing: 0) {
                        ForEach(history) { tx in
                            transactionRow(tx)
                            Divider().overlay(.white.opacity(0.05)).padding(.leading, 56)
                        }
                    }
                } else {
                    ClanEmptyState(icon: "tray", title: "لا تبرّعات بعد", subtitle: "كن أول من يتبرّع للخزينة")
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
    }

    private var treasuryHeader: some View {
        VStack(spacing: AppSizes.Spacing.xs) {
            Text("🪙")
                .font(.system(size: 48))

            Text("\(treasury)")
                .font(.poppins(.black, size: 36))
                .foregroundStyle(Color(hex: "FFD700"))
                .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 10)

            Text("خزينة العشيرة")
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.xl)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFD700").opacity(0.15), Color(hex: "FFD700").opacity(0.02)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1.5)
        )
    }

    private var donateButton: some View {
        Button {
            HapticManager.medium()
            onDonate()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("تبرّع للخزينة")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                Spacer()
                Text("رصيدك: \(myGold) 🪙")
                    .font(.poppins(.semiBold, size: 11))
                    .foregroundStyle(.black.opacity(0.6))
            }
            .foregroundStyle(.black)
            .padding(AppSizes.Spacing.md)
            .background(
                LinearGradient(colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        }
    }

    private func transactionRow(_ tx: TreasuryTransaction) -> some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            AvatarView(imageURL: tx.user?.avatarUrl, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.user?.username ?? "—")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                if let n = tx.note {
                    Text(n).font(.cairo(.regular, size: 10)).foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
            Text("+\(tx.amount) 🪙")
                .font(.poppins(.bold, size: 13))
                .foregroundStyle(AppColors.Default.success)
        }
        .padding(.horizontal, AppSizes.Spacing.sm)
        .padding(.vertical, AppSizes.Spacing.sm)
    }
}

// MARK: - Wars Tab (MVP)
struct ClanWarsTab: View {
    let war: ClanWar?
    let isLoading: Bool

    var body: some View {
        ScrollView {
            if isLoading && war == nil {
                SkeletonList(count: 3).padding(.top, AppSizes.Spacing.sm)
            } else if let war {
                warCard(war)
                    .padding(AppSizes.Spacing.lg)
            } else {
                VStack(spacing: AppSizes.Spacing.md) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("لا توجد حرب حالياً")
                        .font(.cairo(.bold, size: AppSizes.Font.title3))
                        .foregroundStyle(.white)
                    Text("الحروب الأسبوعية قريباً ⚔️")
                        .font(.cairo(.regular, size: AppSizes.Font.body))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, AppSizes.Spacing.xxl)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func warCard(_ war: ClanWar) -> some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // Status banner
            statusBadge(for: war)

            // VS عرض
            HStack(spacing: AppSizes.Spacing.md) {
                sideView(
                    name: war.myClan.name,
                    badge: war.myClan.badge,
                    color: war.displayColorMine,
                    score: war.myClan.score,
                    isWinning: war.myClan.score >= war.enemyClan.score
                )

                Text("VS")
                    .font(.poppins(.black, size: 18))
                    .foregroundStyle(.white.opacity(0.6))

                sideView(
                    name: war.enemyClan.name,
                    badge: war.enemyClan.badge,
                    color: war.displayColorEnemy,
                    score: war.enemyClan.score,
                    isWinning: war.enemyClan.score > war.myClan.score
                )
            }

            if war.isEnded {
                Text(war.didWin ? "🏆 فزنا!" : "💔 الخسارة")
                    .font(.cairo(.bold, size: AppSizes.Font.title3))
                    .foregroundStyle(war.didWin ? AppColors.Default.success : AppColors.Default.error)
            }
        }
        .padding(AppSizes.Spacing.md)
        .background(Color(hex: "12103B").opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                .stroke(AppColors.Default.goldPrimary.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func statusBadge(for war: ClanWar) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(war.isActive ? AppColors.Default.success : .gray)
                .frame(width: 8, height: 8)
            Text(war.status == .active ? "حرب جارية" : war.status == .scheduled ? "قريباً" : "انتهت")
                .font(.cairo(.semiBold, size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(.white.opacity(0.05))
        .clipShape(Capsule())
    }

    private func sideView(name: String, badge: String?, color: Color, score: Int, isWinning: Bool) -> some View {
        VStack(spacing: 6) {
            ClanBadgeView(badge: badge, color: color, size: 56)
            Text(name)
                .font(.cairo(.bold, size: AppSizes.Font.caption))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("\(score)")
                .font(.poppins(.black, size: 24))
                .foregroundStyle(isWinning ? Color(hex: "FFD700") : .white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
