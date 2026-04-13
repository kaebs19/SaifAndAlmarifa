//
//  PlayerCardPopup.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//
//  Path: SaifAndAlmarifa/Components/PlayerCardPopup.swift
//  بطاقة عرض بيانات اللاعب (popup) — يُستخدم للملف الشخصي ولعرض بيانات الخصوم

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

    /// إنشاء من User + Stats
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

// MARK: - بطاقة اللاعب
struct PlayerCardPopup: View {
    let data: PlayerCardData
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // خلفية معتمة
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            // البطاقة
            VStack(spacing: 0) {
                cardContent
            }
            .frame(maxWidth: 340)
            .background(Color(hex: "12103B"))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                    .stroke(tierColor.opacity(0.5), lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(AppSizes.Spacing.sm)
            }
            .shadow(color: tierColor.opacity(0.3), radius: 20)
            .padding(.horizontal, AppSizes.Spacing.lg)
        }
    }

    // MARK: محتوى البطاقة
    private var cardContent: some View {
        VStack(spacing: 0) {
            // ═══ القسم العلوي — الأفاتار + الاسم ═══
            VStack(spacing: AppSizes.Spacing.sm) {
                AvatarView(imageURL: data.avatarUrl, size: 80)
                    .overlay(Circle().stroke(tierColor, lineWidth: 3))
                    .shadow(color: tierColor.opacity(0.5), radius: 10)

                Text(data.username)
                    .font(.cairo(.black, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)

                // الدولة
                if let country = data.country {
                    HStack(spacing: 4) {
                        Text(CountryList.all.first { $0.id == country }?.flag ?? "🌍")
                        Text(CountryList.all.first { $0.id == country }?.nameAr ?? "")
                            .font(.cairo(.medium, size: AppSizes.Font.caption))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSizes.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [tierColor.opacity(0.2), Color(hex: "12103B")],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // ═══ المعلومات الأساسية ═══
            HStack {
                if let code = data.friendCode, !code.isEmpty {
                    VStack(spacing: 2) {
                        Text(code)
                            .font(.poppins(.bold, size: AppSizes.Font.bodyLarge))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                            .kerning(2)
                        Text("كود الصداقة")
                            .font(.cairo(.regular, size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Text(tierEmoji).font(.system(size: 18))
                    Text(tierLabel)
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(tierColor)
                }
            }
            .padding(.horizontal, AppSizes.Spacing.md)
            .padding(.vertical, AppSizes.Spacing.sm)

            Divider().overlay(tierColor.opacity(0.15))

            // ═══ الإحصائيات ═══
            VStack(spacing: AppSizes.Spacing.xs) {
                Text("الإحصائيات")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .padding(.top, AppSizes.Spacing.sm)

                let s = data.stats
                statsGrid([
                    ("مرات الفوز", "\(s?.wins ?? 0) / \(s?.totalMatches ?? 0)"),
                    ("إجابات صحيحة", "\(s?.totalCorrectAnswers ?? 0)"),
                    ("معدل الفوز", "\(s?.winRate ?? 0)%"),
                    ("مكاسب متتابعة", "\(s?.currentStreak ?? 0)"),
                    ("فوز 1v1", "\(s?.wins1v1 ?? 0)"),
                    ("فوز 4 لاعبين", "\(s?.wins4player ?? 0)"),
                    ("عدد القتل", "\(s?.totalKills ?? 0)"),
                    ("المستوى", "\(data.level)"),
                ])
            }
            .padding(.horizontal, AppSizes.Spacing.md)
            .padding(.bottom, AppSizes.Spacing.lg)
            .background(Color(hex: "12103B"))
        }
    }

    // MARK: شبكة الإحصائيات
    private func statsGrid(_ items: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSizes.Spacing.xs) {
            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text(item.1)
                        .font(.poppins(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, AppSizes.Spacing.sm)
                .background(.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Tier Helpers
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
        case 1...5: return "برونزي"
        case 6...15: return "فضي"
        case 16...30: return "ذهبي"
        case 31...50: return "بلاتيني"
        default: return "أسطوري"
        }
    }

    private var tierEmoji: String {
        switch data.level {
        case 1...5: return "🥉"
        case 6...15: return "🥈"
        case 16...30: return "🥇"
        case 31...50: return "💎"
        default: return "👑"
        }
    }
}

// MARK: - ViewModifier لسهولة الاستخدام
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
