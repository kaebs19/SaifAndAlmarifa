//
//  BattleAnimations.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/BattleAnimations.swift
//  مؤثّرات قتالية سينمائية: cannonball, impact, debris, screen shake, HP drain
//

import SwiftUI

// MARK: - Cannonball Projectile (مسار قوسي من قلعة لأخرى)
struct CannonballLayer: View {
    let isFiring: Bool
    let fromMine: Bool   // true = قلعتي → الخصم، false = الخصم → قلعتي

    @State private var progress: CGFloat = 0
    @State private var trailPoints: [CGPoint] = []

    var body: some View {
        GeometryReader { geo in
            let startX = fromMine ? geo.size.width * 0.18 : geo.size.width * 0.82
            let endX   = fromMine ? geo.size.width * 0.82 : geo.size.width * 0.18
            let baseY  = geo.size.height * 0.45
            let arc    = geo.size.height * 0.35

            // Parabolic position
            let x = startX + (endX - startX) * progress
            let y = baseY - 4 * arc * progress * (1 - progress)

            ZStack {
                if isFiring && progress > 0 && progress < 1 {
                    // Trail (smoke)
                    ForEach(0..<trailPoints.count, id: \.self) { i in
                        let p = trailPoints[i]
                        let alpha = Double(i) / Double(max(trailPoints.count, 1))
                        Circle()
                            .fill(Color(hex: "FFB800").opacity(alpha * 0.4))
                            .frame(width: 10 + CGFloat(i), height: 10 + CGFloat(i))
                            .blur(radius: 4)
                            .position(x: p.x, y: p.y)
                    }

                    // Cannonball
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "FFE55C"), Color(hex: "FF6B35"), Color(hex: "8B0000")],
                                    center: .topLeading,
                                    startRadius: 2, endRadius: 18
                                )
                            )
                            .frame(width: 26, height: 26)
                            .shadow(color: Color(hex: "FF6B35"), radius: 12)
                        // Spinning highlight
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 22, height: 22)
                            .rotationEffect(.degrees(progress * 720))
                    }
                    .position(x: x, y: y)
                }
            }
            .onChange(of: isFiring) { _, new in
                if new {
                    progress = 0
                    trailPoints = []
                    Task { @MainActor in
                        withAnimation(.easeOut(duration: 0.6)) {
                            progress = 1
                        }
                        // collect trail points
                        for i in 1...8 {
                            let p = CGFloat(i) / 8.0
                            let tx = startX + (endX - startX) * p
                            let ty = baseY - 4 * arc * p * (1 - p)
                            trailPoints.append(CGPoint(x: tx, y: ty))
                            try? await Task.sleep(nanoseconds: 50_000_000)
                        }
                    }
                } else {
                    trailPoints = []
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Impact Burst (شرارة + shockwave عند الاصطدام)
struct ImpactBurst: View {
    let nonce: Int
    let onMyCastle: Bool   // true = قلعتي ضُربت

    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var flashOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            let x = onMyCastle ? geo.size.width * 0.18 : geo.size.width * 0.82
            let y = geo.size.height * 0.55

            ZStack {
                // Flash circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FFE55C"),
                                Color(hex: "FF6B35").opacity(0.6),
                                .clear
                            ],
                            center: .center, startRadius: 5, endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .opacity(flashOpacity)
                    .blur(radius: 4)

                // Shockwave ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFB800").opacity(0.9),
                                Color(hex: "FF6B35").opacity(0.4),
                                .clear
                            ],
                            startPoint: .center, endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
            }
            .position(x: x, y: y)
        }
        .allowsHitTesting(false)
        .onChange(of: nonce) { _, _ in
            ringScale = 0.3
            ringOpacity = 1
            flashOpacity = 1
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 2.4
                ringOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.25)) {
                flashOpacity = 0
            }
        }
    }
}

// MARK: - Debris Particles (حطام يتطاير عند الضربة)
struct DebrisField: View {
    let nonce: Int
    let onMyCastle: Bool
    var particleCount: Int = 14

    var body: some View {
        GeometryReader { geo in
            let x = onMyCastle ? geo.size.width * 0.18 : geo.size.width * 0.82
            let y = geo.size.height * 0.55
            ZStack {
                ForEach(0..<particleCount, id: \.self) { i in
                    DebrisParticle(index: i, total: particleCount, nonce: nonce)
                }
            }
            .position(x: x, y: y)
        }
        .allowsHitTesting(false)
    }
}

private struct DebrisParticle: View {
    let index: Int
    let total: Int
    let nonce: Int

    @State private var progress: CGFloat = 0

    private var angle: Double {
        let baseAngle = Double(index) / Double(total) * 2 * .pi
        // Slight bias upward
        return baseAngle - .pi / 2 + Double.random(in: -0.4...0.4)
    }
    private var distance: CGFloat { CGFloat.random(in: 60...110) }
    private var size: CGFloat { CGFloat.random(in: 4...9) }
    private var rotationEnd: Double { Double.random(in: 180...720) }

    private var color: Color {
        [Color(hex: "8B7355"), Color(hex: "A0522D"), Color(hex: "696969"),
         Color(hex: "FFB800")].randomElement()!
    }

    var body: some View {
        let dx = cos(angle) * distance * progress
        let dy = sin(angle) * distance * progress + 50 * progress * progress  // gravity drop
        return RoundedRectangle(cornerRadius: 1)
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotationEnd * Double(progress)))
            .offset(x: dx, y: dy)
            .opacity(1 - Double(progress))
            .onChange(of: nonce) { _, _ in
                progress = 0
                withAnimation(.easeOut(duration: 0.9)) {
                    progress = 1
                }
            }
    }
}

// MARK: - Screen Shake Modifier
struct ScreenShakeModifier: ViewModifier {
    let nonce: Int
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 4

    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeOffset(amount: amount, shakes: shakesPerUnit, animatableData: phase))
            .onChange(of: nonce) { _, _ in
                phase = 0
                withAnimation(.linear(duration: 0.4)) { phase = 1 }
            }
    }
}

private struct ShakeOffset: GeometryEffect {
    var amount: CGFloat
    var shakes: CGFloat
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = amount * sin(animatableData * .pi * shakes) * (1 - animatableData)
        let dy = amount * 0.5 * cos(animatableData * .pi * shakes * 1.5) * (1 - animatableData)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: dy))
    }
}

extension View {
    func screenShake(triggeredBy nonce: Int, amount: CGFloat = 10) -> some View {
        modifier(ScreenShakeModifier(nonce: nonce, amount: amount))
    }
}

// MARK: - HP Damage Flash (يومض على HP bar عند النقص)
struct HPDamageFlash: View {
    let nonce: Int
    @State private var opacity: Double = 0

    var body: some View {
        Capsule()
            .fill(Color.red.opacity(opacity))
            .blur(radius: 6)
            .onChange(of: nonce) { _, _ in
                opacity = 0.8
                withAnimation(.easeOut(duration: 0.5)) { opacity = 0 }
            }
            .allowsHitTesting(false)
    }
}
