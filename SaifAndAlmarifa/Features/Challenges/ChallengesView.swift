//
//  ChallengesView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Challenges/ChallengesView.swift
//  شاشة التحديات — تجميع الأوضاع الخاصة (ضد شخص، ضد صديق، ضد أصحابي)
//  بتصميم جذاب يبرز كل وضع

import SwiftUI

struct ChallengesView: View {

    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showJoinCode = false
    @State private var appear = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSizes.Spacing.md) {
                        subtitle
                            .padding(.top, AppSizes.Spacing.sm)

                        // 1) ضد أصحابي 4 — الأبرز (hero)
                        heroCard(mode: .friends4)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)

                        // 2) ضد صديق
                        modeCard(mode: .challengeFriend)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)

                        // 3) ضد شخص (غرفة بكود)
                        modeCard(mode: .private1v1)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)

                        dividerOr

                        joinCodeCard
                            .opacity(appear ? 1 : 0)
                    }
                    .padding(AppSizes.Spacing.lg)
                    .padding(.bottom, AppSizes.Spacing.xl)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                appear = true
            }
        }
        .sheet(isPresented: $showJoinCode) {
            JoinRoomSheet { code in
                dismiss()
                // delay لتجنب تضارب presentation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    viewModel.joinRoom(code: code)
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - الخلفية
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "08091E"), Color(hex: "12103B"), Color(hex: "0B0A24")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // هالات ملوّنة خلف الكروت
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "F59E0B").opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.1)

                Circle()
                    .fill(Color(hex: "22C55E").opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.5)

                Circle()
                    .fill(Color(hex: "60A5FA").opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.8)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - الهيدر
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("التحديات ⚔️")
                    .font(.cairo(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)
            }
            Spacer()
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.top, AppSizes.Spacing.md)
        .padding(.bottom, AppSizes.Spacing.sm)
    }

    private var subtitle: some View {
        VStack(spacing: 4) {
            Text("تحدى أصدقاءك في مبارزات خاصة")
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.6))
            Text("اختر الوضع المناسب")
                .font(.cairo(.regular, size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Hero Card (الوضع الأبرز)
    private func heroCard(mode: GameMode) -> some View {
        Button {
            selectMode(mode)
        } label: {
            VStack(spacing: AppSizes.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🔥 الأكثر شعبية")
                            .font(.cairo(.semiBold, size: 10))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.white)
                            .clipShape(Capsule())

                        Text(mode.title)
                            .font(.cairo(.black, size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        Text(mode.subtitle)
                            .font(.cairo(.medium, size: AppSizes.Font.body))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    // أيقونة كبيرة
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [mode.accentColor.opacity(0.3), .clear],
                                    center: .center, startRadius: 10, endRadius: 70
                                )
                            )
                            .frame(width: 110, height: 110)
                        Image(mode.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .shadow(color: mode.accentColor.opacity(0.8), radius: 15)
                    }
                }

                // التفاصيل
                HStack(spacing: AppSizes.Spacing.sm) {
                    ForEach(Array(mode.details.enumerated()), id: \.offset) { _, d in
                        detailChip(icon: d.icon, text: "\(d.value) \(d.label)")
                    }
                    Spacer()
                }
            }
            .padding(AppSizes.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [Color(hex: "3D2B00"), Color(hex: "2A1F00"), Color(hex: "1A1200")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "B8860B").opacity(0.3)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color(hex: "FFD700").opacity(0.2), radius: 20, y: 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Standard Mode Card
    private func modeCard(mode: GameMode) -> some View {
        Button {
            selectMode(mode)
        } label: {
            HStack(spacing: AppSizes.Spacing.md) {
                // الأيقونة مع هالة
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [mode.accentColor.opacity(0.3), .clear],
                                center: .center, startRadius: 5, endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                    Image(mode.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .shadow(color: mode.accentColor.opacity(0.6), radius: 8)
                }

                // النصوص
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.cairo(.bold, size: AppSizes.Font.title3))
                        .foregroundStyle(.white)

                    Text(mode.subtitle)
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)

                    HStack(spacing: AppSizes.Spacing.xs) {
                        detailChip(icon: "person.2.fill", text: "\(mode.playersRequired)")
                        detailChip(icon: "clock.fill", text: "~\(mode.estimatedMinutes)د")
                        detailChip(icon: "trophy.fill", text: "+\(mode.winReward)🪙")
                    }
                }

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(mode.accentColor.opacity(0.6))
            }
            .padding(AppSizes.Spacing.md)
            .background(
                LinearGradient(
                    colors: [mode.accentColor.opacity(0.15), mode.accentColor.opacity(0.03)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.large)
                    .stroke(mode.accentColor.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Detail Chip
    private func detailChip(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.poppins(.semiBold, size: 10))
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(.white.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Divider "أو"
    private var dividerOr: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
            Text("أو")
                .font(.cairo(.medium, size: 11))
                .foregroundStyle(.white.opacity(0.4))
            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
        }
        .padding(.vertical, AppSizes.Spacing.xs)
    }

    // MARK: - Join by Code Card
    private var joinCodeCard: some View {
        Button {
            HapticManager.light()
            showJoinCode = true
        } label: {
            HStack(spacing: AppSizes.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "6366F1").opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "A78BFA"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("الانضمام بكود")
                        .font(.cairo(.bold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                    Text("تملك كود غرفة؟ انضم مباشرة")
                        .font(.cairo(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "A78BFA").opacity(0.6))
            }
            .padding(AppSizes.Spacing.md)
            .background(Color(hex: "6366F1").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(Color(hex: "6366F1").opacity(0.25),
                            style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Select Mode (يُغلق الشاشة ثم يفتح اللوبي)
    private func selectMode(_ mode: GameMode) {
        HapticManager.medium()
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            viewModel.selectMode(mode)
        }
    }
}
