//
//  EndCinematic.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/EndCinematic.swift
//  مؤثّرات سينمائية لشاشة نهاية المباراة: victory beam، crumble، outro
//

import SwiftUI

// MARK: - Victory Beam (عمود ضوء ذهبي ينزل من السماء)
struct VictoryBeam: View {
    @State private var beamHeight: CGFloat = 0
    @State private var beamOpacity: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // العمود الذهبي
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFE55C").opacity(0.7),
                                Color(hex: "FFD700").opacity(0.4),
                                Color(hex: "FFB800").opacity(0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: beamHeight)
                    .blur(radius: pulse ? 14 : 8)
                    .opacity(beamOpacity)
                    .shadow(color: Color(hex: "FFD700").opacity(0.7), radius: 20)

                // طبقة داخلية أبرق
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 16, height: beamHeight)
                    .blur(radius: 4)
                    .opacity(beamOpacity)
            }
            .position(x: geo.size.width / 2, y: beamHeight / 2)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            // العمود ينزل من فوق
            withAnimation(.easeOut(duration: 1.0)) {
                beamHeight = UIScreen.main.bounds.height
                beamOpacity = 1
            }
            // pulse ذهبي
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}

// MARK: - Castle Crumble (تحطّم بطيء عند الخسارة)
struct CastleCrumble: View {
    @State private var fragmentsProgress: CGFloat = 0
    @State private var fadeProgress: Double = 0

    var body: some View {
        ZStack {
            // Castle silhouette ينهار
            Image(systemName: "building.columns.fill")
                .font(.system(size: 100, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "8B7355"), Color(hex: "5D4E37")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .opacity(1 - fadeProgress)
                .rotationEffect(.degrees(fadeProgress * 8))
                .offset(y: fadeProgress * 30)
                .blur(radius: fadeProgress * 4)

            // 16 fragment يتطاير
            ForEach(0..<16, id: \.self) { i in
                CrumbleFragment(index: i, progress: fragmentsProgress)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) {
                fragmentsProgress = 1
            }
            withAnimation(.easeIn(duration: 1.0).delay(0.1)) {
                fadeProgress = 1
            }
        }
    }
}

private struct CrumbleFragment: View {
    let index: Int
    let progress: CGFloat

    private var angle: Double {
        Double(index) / 16 * 2 * .pi + Double.random(in: -0.4...0.4)
    }
    private var distance: CGFloat { CGFloat.random(in: 80...140) }
    private var fallExtra: CGFloat { CGFloat.random(in: 100...180) }
    private var size: CGFloat { CGFloat.random(in: 8...14) }

    var body: some View {
        let dx = cos(angle) * distance * progress
        let dy = sin(angle) * distance * progress + fallExtra * progress * progress
        return RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "8B7355"), Color(hex: "5D4E37")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(Double(progress) * 360))
            .offset(x: dx, y: dy)
            .opacity(1 - Double(progress))
    }
}

// MARK: - Enhanced Confetti (نجوم + قلوب + قطع متعرّجة)
struct EnhancedConfetti: View {
    var count: Int = 60

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    EnhancedConfettiPiece(index: i, screenSize: geo.size)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct EnhancedConfettiPiece: View {
    let index: Int
    let screenSize: CGSize

    @State private var offsetY: CGFloat = -50
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    private var x: CGFloat { CGFloat.random(in: 0...screenSize.width) }
    private var endY: CGFloat { screenSize.height + 100 }
    private var duration: Double { Double.random(in: 2.5...4.5) }
    private var delay: Double { Double(index) * 0.04 }

    private var icon: String {
        ["star.fill", "heart.fill", "sparkle", "diamond.fill"].randomElement()!
    }
    private var color: Color {
        [Color(hex: "FFD700"), Color(hex: "EF4444"), Color(hex: "10B981"),
         Color(hex: "60A5FA"), Color(hex: "A78BFA"), Color(hex: "F59E0B")]
            .randomElement()!
    }
    private var size: CGFloat { CGFloat.random(in: 12...22) }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size, weight: .black))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.5), radius: 4)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(x: x, y: offsetY)
            .onAppear {
                withAnimation(.linear(duration: duration).delay(delay)) {
                    offsetY = endY
                    rotation = Double.random(in: 360...1080)
                }
                withAnimation(.easeIn(duration: 0.5).delay(delay + duration - 0.5)) {
                    opacity = 0
                }
            }
    }
}
