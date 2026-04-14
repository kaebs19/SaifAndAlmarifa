//
//  PlayerCardPopup.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//
//  بطاقة عرض بيانات اللاعب — popup مثل لودو ستار

import SwiftUI

// MARK: - بيانات البطاقة
struct PlayerCardData {
    let username: String
    let avatarUrl: String?
    let country: String?
    let level: Int
    let gems: Int
    let friendCode: String?
    let stats: UserStats?

    static func from(user: User, stats: UserStats? = nil) -> PlayerCardData {
        PlayerCardData(
            username: user.username,
            avatarUrl: user.fullAvatarUrl,
            country: user.country,
            level: user.level ?? 1,
            gems: user.gems ?? 0,
            friendCode: user.friendCode,
            stats: stats
        )
    }
}

// MARK: - بطاقة اللاعب (Popup)
struct PlayerCardPopup: View {
    let data: PlayerCardData
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { onClose() }

            card
                .padding(.horizontal, 32)
        }
    }

    // MARK: البطاقة
    private var card: some View {
        VStack(spacing: 0) {
            // ═══ القسم العلوي — الأفاتار + الاسم + الدولة ═══
            ZStack(alignment: .topTrailing) {
                VStack(spacing: AppSizes.Spacing.md) {
                    // الأفاتار
                    AsyncImage(url: URL(string: data.avatarUrl ?? "")) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32)).foregroundStyle(.gray.opacity(0.5))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(tierColor, lineWidth: 3))
                    .shadow(color: tierColor.opacity(0.5), radius: 10)

                    // الاسم
                    Text(data.username)
                        .font(.cairo(.black, size: AppSizes.Font.title2))
                        .foregroundStyle(.white)

                    // الدولة
                    if let c = data.country, let country = CountryList.all.first(where: { $0.id == c }) {
                        HStack(spacing: 6) {
                            Text(country.flag).font(.system(size: 18))
                            Text(country.nameAr)
                                .font(.cairo(.medium, size: AppSizes.Font.body))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSizes.Spacing.xl)
                .padding(.top, AppSizes.Spacing.sm)

                // زر الإغلاق
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(AppSizes.Spacing.md)
            }
            .background(
                LinearGradient(
                    colors: [tierColor.opacity(0.2), Color(hex: "0E1236")],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // ═══ الرتبة + كود ═══
            HStack {
                if let code = data.friendCode, !code.isEmpty {
                    Text(code)
                        .font(.poppins(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                        .kerning(2)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text(tierEmoji).font(.system(size: 16))
                    Text(tierLabel)
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(tierColor)
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.vertical, AppSizes.Spacing.sm)
            .background(Color(hex: "0E1236"))

            // ═══ الإحصائيات ═══
            VStack(spacing: 1) {
                statRow("مرات الفوز", value: "\(data.stats?.wins ?? 0) / \(data.stats?.totalMatches ?? 0)")
                statRow("معدل الفوز", value: "\(data.stats?.winRate ?? 0)%")
                statRow("مكاسب متتابعة", value: "\(data.stats?.currentStreak ?? 0)")
                statRow("فوز 1v1", value: "\(data.stats?.wins1v1 ?? 0)")
                statRow("فوز 4 لاعبين", value: "\(data.stats?.wins4player ?? 0)")
                statRow("عدد القتل", value: "\(data.stats?.totalKills ?? 0)")
            }
            .background(Color(hex: "0E1236"))
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                .stroke(tierColor.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: tierColor.opacity(0.2), radius: 20)
    }

    // MARK: صف إحصائية واحد
    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.poppins(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(.white.opacity(0.02))
    }

    // MARK: - Tier
    private var tierColor: Color {
        switch data.level {
        case 1...5: return AppColors.Tier.bronze
        case 6...15: return AppColors.Tier.silver
        case 16...30: return AppColors.Tier.gold
        case 31...50: return AppColors.Tier.platinum
        default: return AppColors.Tier.diamond
        }
    }
    private var tierLabel: String {
        switch data.level {
        case 1...5: return "برونزي"; case 6...15: return "فضي"; case 16...30: return "ذهبي"; case 31...50: return "بلاتيني"; default: return "أسطوري"
        }
    }
    private var tierEmoji: String {
        switch data.level {
        case 1...5: return "🥉"; case 6...15: return "🥈"; case 16...30: return "🥇"; case 31...50: return "💎"; default: return "👑"
        }
    }
}

// MARK: - ViewModifier
struct PlayerCardModifier: ViewModifier {
    @Binding var isPresented: Bool
    let data: PlayerCardData?

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented, let data {
                PlayerCardPopup(data: data) {
                    withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func playerCard(isPresented: Binding<Bool>, data: PlayerCardData?) -> some View {
        modifier(PlayerCardModifier(isPresented: isPresented, data: data))
    }
}
