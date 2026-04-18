//
//  AdminSheets.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/AdminSheets.swift
//  شيتات أدوات الأدمن: التبليغ، الكتم

import SwiftUI

// MARK: - شيت التبليغ عن رسالة
struct ReportReasonSheet: View {

    let message: ClanMessage
    var onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String = ""
    @State private var customReason: String = ""

    private let reasons = [
        "محتوى مسيء",
        "spam أو إعلانات",
        "احتيال / نصب",
        "كلام تحريضي",
        "انتحال شخصية",
        "أخرى"
    ]

    var body: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // Handle
            Capsule().fill(.white.opacity(0.2)).frame(width: 36, height: 4).padding(.top, 8)

            Text("تبليغ عن رسالة")
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(.white)

            // اختيار السبب
            VStack(spacing: 6) {
                ForEach(reasons, id: \.self) { reason in
                    Button {
                        HapticManager.selection()
                        selectedReason = reason
                    } label: {
                        HStack {
                            Image(systemName: selectedReason == reason ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(selectedReason == reason ? AppColors.Default.goldPrimary : .white.opacity(0.4))
                            Text(reason)
                                .font(.cairo(.medium, size: AppSizes.Font.body))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(AppSizes.Spacing.sm)
                        .background(selectedReason == reason ? AppColors.Default.goldPrimary.opacity(0.08) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)

            Spacer()

            Button {
                let reason = selectedReason == "أخرى" ? customReason : selectedReason
                onSubmit(reason.isEmpty ? "غير محدد" : reason)
            } label: {
                Text("إرسال البلاغ")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .background(selectedReason.isEmpty ? .gray : AppColors.Default.goldPrimary)
                    .clipShape(Capsule())
            }
            .disabled(selectedReason.isEmpty)
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.md)
        }
        .background(GradientBackground.main)
    }
}

// MARK: - شيت كتم عضو
struct MuteMemberSheet: View {

    let member: ClanMember
    var onConfirm: (Int) -> Void  // minutes

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Int = 60

    private let options: [(label: String, minutes: Int)] = [
        ("10 دقائق", 10),
        ("30 دقيقة", 30),
        ("ساعة", 60),
        ("6 ساعات", 360),
        ("يوم كامل", 1440),
        ("أسبوع", 10080)
    ]

    var body: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Capsule().fill(.white.opacity(0.2)).frame(width: 36, height: 4).padding(.top, 8)

            HStack(spacing: AppSizes.Spacing.sm) {
                AvatarView(imageURL: member.avatarUrl, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("كتم \(member.username)")
                        .font(.cairo(.bold, size: AppSizes.Font.title3))
                        .foregroundStyle(.white)
                    Text("خلال الكتم لا يقدر يرسل رسائل")
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal, AppSizes.Spacing.lg)

            // اختيار المدة
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(options, id: \.minutes) { opt in
                    Button {
                        HapticManager.selection()
                        selectedMinutes = opt.minutes
                    } label: {
                        Text(opt.label)
                            .font(.cairo(.semiBold, size: 11))
                            .foregroundStyle(selectedMinutes == opt.minutes ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSizes.Spacing.sm)
                            .background(selectedMinutes == opt.minutes ? AppColors.Default.goldPrimary : .white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)

            Spacer()

            Button {
                onConfirm(selectedMinutes)
            } label: {
                Label("كتم الآن", systemImage: "mic.slash")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .background(AppColors.Default.error)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.md)
        }
        .background(GradientBackground.main)
    }
}

// MARK: - Identifiable conformance للـ ClanMessage (للـ sheet(item:))
extension ClanMessage: @retroactive Equatable {
    public static func == (lhs: ClanMessage, rhs: ClanMessage) -> Bool { lhs.id == rhs.id }
}

// MARK: - شيت التبرّع للخزينة
struct TreasuryDonateSheet: View {

    let myGold: Int
    var onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount: Int = 50

    private let presets = [10, 50, 100, 250, 500, 1000]

    var body: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Capsule().fill(.white.opacity(0.2)).frame(width: 36, height: 4).padding(.top, 8)

            Text("تبرّع للخزينة")
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(.white)

            Text("رصيدك: \(myGold) 🪙")
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))

            // المبلغ المختار
            HStack(spacing: 4) {
                Text("\(amount)")
                    .font(.poppins(.black, size: 42))
                    .foregroundStyle(Color(hex: "FFD700"))
                Text("🪙").font(.system(size: 28))
            }

            // presets
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(presets.filter { $0 <= myGold }, id: \.self) { value in
                    Button {
                        HapticManager.selection()
                        amount = value
                    } label: {
                        Text("\(value)")
                            .font(.poppins(.bold, size: 13))
                            .foregroundStyle(amount == value ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSizes.Spacing.sm)
                            .background(amount == value ? AppColors.Default.goldPrimary : .white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal, AppSizes.Spacing.lg)

            Spacer()

            Button {
                onConfirm(amount)
            } label: {
                Text("تبرّع الآن")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .background(amount > myGold || amount <= 0 ? .gray : AppColors.Default.goldPrimary)
                    .clipShape(Capsule())
            }
            .disabled(amount > myGold || amount <= 0)
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.md)
        }
        .background(GradientBackground.main)
    }
}

// MARK: - Identifiable conformance للـ ClanMember (للـ sheet(item:))
// Already Identifiable via id
