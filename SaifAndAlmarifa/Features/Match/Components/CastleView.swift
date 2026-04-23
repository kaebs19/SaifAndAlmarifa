//
//  CastleView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Match/Components/CastleView.swift
//  مكوّن عرض القلعة مع طبقات ضرر حسب HP

import SwiftUI

struct CastleView: View {
    let side: CastleSide
    /// قيمة من 0 إلى 100 (نسبة الصحة)
    let hpPercentage: Int
    /// هل تهتز الآن (عند التعرض لضربة)
    var isShaking: Bool = false
    /// هل الدرع مفعّل (aura حولها)
    var shieldActive: Bool = false

    @State private var breath: Bool = false
    @State private var auraPulse: Bool = false

    var body: some View {
        ZStack {
            // Shield aura (يدور حولها)
            if shieldActive {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "60A5FA"), Color(hex: "93C5FD")],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 2)
                    .scaleEffect(auraPulse ? 1.15 : 1.05)
                    .opacity(auraPulse ? 0.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: auraPulse
                    )
            }

            // القلعة الأساسية (مع تنفّس)
            side.image
                .resizable()
                .scaledToFit()

            // طبقات الضرر التراكمية
            if hpPercentage <= 75 && hpPercentage > 0 {
                DamageStage.cracks.image
                    .resizable()
                    .scaledToFit()
                    .opacity(0.6)
                    .transition(.opacity)
            }

            if hpPercentage <= 50 && hpPercentage > 0 {
                DamageStage.smoke.image
                    .resizable()
                    .scaledToFit()
                    .opacity(0.7)
                    .transition(.opacity)
            }

            if hpPercentage <= 25 && hpPercentage > 0 {
                DamageStage.fire.image
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            }

            if hpPercentage == 0 {
                DamageStage.rubble.image
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            }
        }
        .rotationEffect(.degrees(isShaking ? 2 : 0))
        .offset(x: isShaking ? -3 : 0, y: isShaking ? 2 : 0)
        .scaleEffect(breath ? 1.025 : 1.0)   // تنفّس خفيف
        .animation(.easeInOut(duration: 0.6), value: hpPercentage)
        .animation(
            isShaking
                ? .linear(duration: 0.08).repeatCount(4, autoreverses: true)
                : .default,
            value: isShaking
        )
        .animation(
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
            value: breath
        )
        .onAppear {
            breath = true
            auraPulse = true
        }
    }
}

// MARK: - HP Bar (يُعرض بجانب/تحت القلعة)
struct CastleHPBar: View {
    /// النسبة من 0 إلى 1
    let percent: Double
    let color: Color

    @State private var warningPulse: Bool = false

    private var isCritical: Bool { percent <= 0.25 && percent > 0 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // الخلفية (أسود + حجارة)
                Capsule()
                    .fill(Color.black.opacity(0.6))
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)

                // الـ fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0, min(1, percent)))
                    .shadow(color: color.opacity(0.6), radius: 4)

                // Critical warning overlay (يومض أحمر)
                if isCritical {
                    Capsule()
                        .fill(Color.red.opacity(warningPulse ? 0.5 : 0.1))
                        .frame(width: geo.size.width * max(0, min(1, percent)))
                }
            }
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.4), value: percent)
        .animation(
            .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
            value: warningPulse
        )
        .onAppear { warningPulse = true }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 30) {
            VStack {
                CastleView(side: .player, hpPercentage: 100)
                    .frame(width: 120, height: 120)
                Text("100%").foregroundStyle(.white)
            }
            VStack {
                CastleView(side: .enemy, hpPercentage: 60)
                    .frame(width: 120, height: 120)
                Text("60%").foregroundStyle(.white)
            }
        }
        HStack(spacing: 30) {
            VStack {
                CastleView(side: .player, hpPercentage: 20, isShaking: true)
                    .frame(width: 120, height: 120)
                Text("20% + shake").foregroundStyle(.white)
            }
            VStack {
                CastleView(side: .enemy, hpPercentage: 0)
                    .frame(width: 120, height: 120)
                Text("0%").foregroundStyle(.white)
            }
        }

        CastleHPBar(percent: 0.6, color: .green)
            .padding()
    }
    .padding(40)
    .background(Color.black)
}
