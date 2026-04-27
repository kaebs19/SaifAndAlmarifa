//
//  AtmosphereLayers.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/AtmosphereLayers.swift
//  طبقات جوّية للخلفية: سحاب، برق، جنود silhouettes، قمر
//

import SwiftUI

// MARK: - Drifting Clouds (سحاب يطفو ببطء)
struct DriftingClouds: View {
    let phase: MatchPhase   // يحدّد الـ tint

    @State private var animateCloud1: Bool = false
    @State private var animateCloud2: Bool = false
    @State private var animateCloud3: Bool = false

    private var tint: Color {
        phase == .battle ? Color(hex: "FF6B35").opacity(0.10) : Color.white.opacity(0.06)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                cloud(at: CGPoint(
                    x: animateCloud1 ? geo.size.width + 60 : -80,
                    y: geo.size.height * 0.15
                ), size: 110)

                cloud(at: CGPoint(
                    x: animateCloud2 ? geo.size.width + 60 : -80,
                    y: geo.size.height * 0.32
                ), size: 80)

                cloud(at: CGPoint(
                    x: animateCloud3 ? geo.size.width + 60 : -80,
                    y: geo.size.height * 0.08
                ), size: 60)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                animateCloud1 = true
            }
            withAnimation(.linear(duration: 90).repeatForever(autoreverses: false).delay(15)) {
                animateCloud2 = true
            }
            withAnimation(.linear(duration: 75).repeatForever(autoreverses: false).delay(30)) {
                animateCloud3 = true
            }
        }
    }

    private func cloud(at position: CGPoint, size: CGFloat) -> some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: size, weight: .black))
            .foregroundStyle(tint)
            .blur(radius: 6)
            .position(position)
    }
}

// MARK: - Lightning Flash (برق يومض في اللحظات الحرجة)
struct LightningFlash: View {
    let nonce: Int
    var color: Color = .white

    @State private var opacity: Double = 0

    var body: some View {
        Color(color)
            .opacity(opacity)
            .ignoresSafeArea()
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .onChange(of: nonce) { _, _ in
                opacity = 0.55
                withAnimation(.easeOut(duration: 0.08)) { opacity = 0 }
                // ومضة ثانية قصيرة
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    opacity = 0.35
                    withAnimation(.easeOut(duration: 0.18)) { opacity = 0 }
                }
            }
    }
}

// MARK: - Distant Army Silhouettes (جنود في الأفق)
struct DistantArmySilhouettes: View {
    let phase: MatchPhase

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 4) {
                ForEach(0..<28, id: \.self) { i in
                    let height = 8 + CGFloat(i % 4) * 3
                    let isFlag = i % 7 == 0

                    if isFlag {
                        // علم مع عمود
                        Rectangle()
                            .fill(.white.opacity(0.12))
                            .frame(width: 1.5, height: 18)
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(phase == .battle
                                          ? Color(hex: "EF4444").opacity(0.35)
                                          : Color(hex: "FFD700").opacity(0.30))
                                    .frame(width: 5, height: 4)
                                    .offset(x: 3.5, y: 0)
                            }
                    } else {
                        // جندي بسيط (دائرة + مستطيل)
                        VStack(spacing: 0) {
                            Circle()
                                .fill(.white.opacity(0.10))
                                .frame(width: 4, height: 4)
                            Rectangle()
                                .fill(.white.opacity(0.10))
                                .frame(width: 3, height: height)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .position(x: geo.size.width / 2, y: geo.size.height - 10)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }
}

// MARK: - Moon/Sun (في الزاوية)
struct CelestialBody: View {
    let phase: MatchPhase

    var body: some View {
        ZStack {
            // halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tintHalo.opacity(0.4), tintHalo.opacity(0)],
                        center: .center, startRadius: 8, endRadius: 50
                    )
                )
                .frame(width: 90, height: 90)
                .blur(radius: 4)

            Image(systemName: phase == .battle ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: phase == .battle
                            ? [Color(hex: "FFE4B5"), Color(hex: "FFD700").opacity(0.9)]
                            : [Color(hex: "FFE55C"), Color(hex: "FFB800")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: tintHalo.opacity(0.5), radius: 12)
        }
        .position(x: 60, y: 90)
        .allowsHitTesting(false)
    }

    private var tintHalo: Color {
        phase == .battle ? Color(hex: "FFE4B5") : Color(hex: "FFD700")
    }
}
