//
//  ConfettiView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Components/ConfettiView.swift
//  مكوّن احتفالي — قصاصات ملوّنة تتساقط عند الفوز

import SwiftUI

struct ConfettiView: View {
    var count: Int = 60

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Rectangle()
                        .fill(p.color)
                        .frame(width: p.size.width, height: p.size.height)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                        .opacity(p.opacity)
                }
            }
            .onAppear {
                spawn(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func spawn(in size: CGSize) {
        particles = (0..<count).map { _ in
            ConfettiParticle.random()
        }
        animate()
    }

    private func animate() {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.8)
            let duration = Double.random(in: 2.5...4.5)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[i].y = 1.15
                particles[i].rotation += Double.random(in: 360...720)
            }
            // تلاشي في النهاية
            withAnimation(.easeOut(duration: 0.6).delay(delay + duration - 0.6)) {
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Particle Model
private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var rotation: Double
    var color: Color
    var size: CGSize
    var opacity: Double = 1

    static func random() -> ConfettiParticle {
        let colors: [Color] = [
            Color(hex: "FFD700"),   // gold
            Color(hex: "FF6B6B"),   // red
            Color(hex: "4ECDC4"),   // teal
            Color(hex: "A78BFA"),   // purple
            Color(hex: "60A5FA"),   // blue
            Color(hex: "22C55E"),   // green
            Color(hex: "F59E0B"),   // orange
            Color.white
        ]
        let w: CGFloat = CGFloat.random(in: 6...14)
        let h: CGFloat = CGFloat.random(in: 10...20)
        return ConfettiParticle(
            x: Double.random(in: 0...1),
            y: Double.random(in: -0.15...(-0.02)),
            rotation: Double.random(in: 0...360),
            color: colors.randomElement()!,
            size: CGSize(width: w, height: h)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView(count: 80)
    }
}
