//
//  RewardAnimations.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/RewardAnimations.swift
//  مؤثّرات الجوائز: float-up، crown للقائد، streak trail، power-up FX
//

import SwiftUI

// MARK: - Floating Points (+N يطفو لأعلى)
struct FloatingPoints: View {
    let nonce: Int
    let amount: Int
    var color: Color = Color(hex: "FFD700")

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.6

    var body: some View {
        Group {
            if nonce > 0 && amount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .black))
                    Text("+\(amount)")
                        .font(.poppins(.black, size: 22))
                        .monospacedDigit()
                }
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.7), radius: 10)
                .offset(y: offset)
                .opacity(opacity)
                .scaleEffect(scale)
            }
        }
        .onChange(of: nonce) { _, _ in
            guard amount > 0 else { return }
            // Reset
            offset = 0
            opacity = 0
            scale = 0.6
            // Pop in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                opacity = 1
                scale = 1.2
            }
            // Float up + fade
            withAnimation(.easeOut(duration: 1.2).delay(0.15)) {
                offset = -60
                opacity = 0
                scale = 0.9
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Crown (تاج فوق القائد — يطفو + يميل + glow نابض)
struct LeaderCrown: View {
    let isLeader: Bool

    @State private var bob: Bool = false
    @State private var tilt: Bool = false
    @State private var glowPulse: Bool = false

    var body: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "B8860B")],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .shadow(color: Color(hex: "FFD700").opacity(glowPulse ? 0.9 : 0.5),
                    radius: glowPulse ? 10 : 5)
            .offset(y: bob ? -3 : 3)
            .rotationEffect(.degrees(tilt ? 6 : -6))
            .opacity(isLeader ? 1 : 0)
            .scaleEffect(isLeader ? 1 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isLeader)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: bob
            )
            .animation(
                .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                value: tilt
            )
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: glowPulse
            )
            .onAppear {
                bob = true
                tilt = true
                glowPulse = true
            }
    }
}

// MARK: - Streak Fire Trail (لهب حول score badge عند streak)
struct StreakFireRing: View {
    let active: Bool

    @State private var rotation: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            if active {
                // حلقة لهب دوّارة
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color(hex: "FFB800"),
                                Color(hex: "FF6B35"),
                                Color(hex: "EF4444"),
                                Color(hex: "FFB800")
                            ],
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(rotation))
                    .blur(radius: 0.5)
                    .shadow(color: Color(hex: "FF6B35").opacity(0.7), radius: pulse ? 8 : 4)

                // 3 شرارات صغيرة
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "flame.fill")
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(Color(hex: "FFB800"))
                        .offset(y: -19)
                        .rotationEffect(.degrees(Double(i) * 120 + rotation))
                }
            }
        }
        .opacity(active ? 1 : 0)
        .animation(
            .linear(duration: 2.5).repeatForever(autoreverses: false),
            value: rotation
        )
        .animation(
            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
            value: pulse
        )
        .onAppear {
            rotation = 360
            pulse = true
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Power-up Activation FX
struct PowerUpActivationBurst: View {
    let nonce: Int
    let color: Color

    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var sparksProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Radial flash
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.8), color.opacity(0.0)],
                        center: .center, startRadius: 5, endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .blur(radius: 4)

            // Expanding ring
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 80, height: 80)
                .scaleEffect(ringScale)
                .opacity(ringOpacity * 0.6)

            // Sparks
            ForEach(0..<10, id: \.self) { i in
                let angle = Double(i) / 10.0 * 2 * .pi
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(angle) * 50 * sparksProgress,
                        y: sin(angle) * 50 * sparksProgress
                    )
                    .opacity(1 - Double(sparksProgress))
            }
        }
        .allowsHitTesting(false)
        .onChange(of: nonce) { _, _ in
            ringScale = 0.3
            ringOpacity = 1
            sparksProgress = 0
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 1.6
                ringOpacity = 0
                sparksProgress = 1
            }
        }
    }
}

// MARK: - Rolling Number (يعدّ من قيمة لأخرى)
struct RollingNumber: View {
    let value: Int
    let font: Font
    var color: Color = .white

    @State private var displayed: Int = 0

    var body: some View {
        Text("\(displayed)")
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText())
            .onAppear { displayed = value }
            .onChange(of: value) { old, new in
                guard new != old else { return }
                let steps = abs(new - old)
                let stepDuration = max(0.5 / Double(steps), 0.04)
                Task { @MainActor in
                    let direction = new > old ? 1 : -1
                    var current = old
                    for _ in 0..<steps {
                        current += direction
                        try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                        withAnimation(.spring(response: 0.15)) { displayed = current }
                    }
                }
            }
    }
}
