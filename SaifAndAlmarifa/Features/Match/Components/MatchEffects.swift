//
//  MatchEffects.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/MatchEffects.swift
//  مؤثّرات بصرية لتجربة لعب احترافية: shake، sparkles، critical HP، combo
//

import SwiftUI

// MARK: - Shake Effect (لاهتزاز إجابة خاطئة)
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

extension View {
    /// Trigger يهتز عند تغيّر nonce
    func shake(triggeredBy nonce: Int) -> some View {
        modifier(ShakeOnChange(nonce: nonce))
    }
}

private struct ShakeOnChange: ViewModifier {
    let nonce: Int
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: phase))
            .onChange(of: nonce) { _, _ in
                phase = 0
                withAnimation(.easeInOut(duration: 0.45)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Sparkle burst (احتفال بالنقاط)
struct SparkleBurst: View {
    let nonce: Int
    let color: Color
    var sparkleCount: Int = 12

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { ctx, size in
                // Canvas بدون animation state — استخدم View modifier بدلاً من ذلك
                _ = ctx; _ = size
            }
        }
        .overlay(
            ZStack {
                ForEach(0..<sparkleCount, id: \.self) { i in
                    SparkleParticle(index: i, total: sparkleCount, color: color, nonce: nonce)
                }
            }
        )
        .allowsHitTesting(false)
    }
}

private struct SparkleParticle: View {
    let index: Int
    let total: Int
    let color: Color
    let nonce: Int

    @State private var progress: CGFloat = 0

    private var angle: Double {
        Double(index) / Double(total) * 2 * .pi + Double.random(in: -0.3...0.3)
    }
    private var distance: CGFloat {
        CGFloat.random(in: 50...90)
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat.random(in: 10...16), weight: .black))
            .foregroundStyle(color)
            .offset(
                x: cos(angle) * distance * progress,
                y: sin(angle) * distance * progress
            )
            .opacity(1 - Double(progress))
            .scaleEffect(0.4 + progress * 0.8)
            .onChange(of: nonce) { _, _ in
                progress = 0
                withAnimation(.easeOut(duration: 0.7).delay(Double.random(in: 0...0.1))) {
                    progress = 1
                }
            }
    }
}

// MARK: - Critical HP Overlay (حواف حمراء نابضة)
struct CriticalHPOverlay: View {
    @State private var pulse: Bool = false

    var body: some View {
        Rectangle()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color(hex: "EF4444"),
                        Color(hex: "EF4444").opacity(0.2)
                    ],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: pulse ? 14 : 6
            )
            .ignoresSafeArea()
            .opacity(pulse ? 0.85 : 0.5)
            .blur(radius: 1.5)
            .allowsHitTesting(false)
            .animation(
                .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = true }
    }
}

// MARK: - Combo Banner (سلسلة إجابات صحيحة)
struct ComboBanner: View {
    let count: Int

    @State private var scaleIn: Bool = false

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFB800"), Color(hex: "F97316")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)

                Text("سلسلة")
                    .font(.cairo(.black, size: 16))
                    .foregroundStyle(.white)

                Text("×\(count)")
                    .font(.poppins(.black, size: 22))
                    .foregroundStyle(Color(hex: "FFD700"))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "FFB800").opacity(0.25),
                        Color(hex: "F97316").opacity(0.15)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "F97316")],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
            )
            .shadow(color: Color(hex: "F97316").opacity(0.5), radius: 14)
            .scaleEffect(scaleIn ? 1.0 : 0.7)
            .padding(.bottom, 140)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                scaleIn = true
            }
        }
        .transition(.scale(scale: 0.6).combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

// MARK: - Opponent Status Indicator
struct OpponentStatusBadge: View {
    let hasAnswered: Bool

    var body: some View {
        HStack(spacing: 4) {
            if hasAnswered {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.Default.success)
                Text("جاوب")
                    .font(.cairo(.bold, size: 9))
                    .foregroundStyle(AppColors.Default.success)
            } else {
                MatchTypingDots()
                    .frame(width: 18, height: 6)
                Text("يكتب")
                    .font(.cairo(.medium, size: 9))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(
                hasAnswered ? AppColors.Default.success.opacity(0.4) : .white.opacity(0.12),
                lineWidth: 1
            )
        )
    }
}

private struct MatchTypingDots: View {
    @State private var phase: Double = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .scaleEffect(dotScale(for: i))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }

    private func dotScale(for index: Int) -> CGFloat {
        let offset = Double(index) * 0.2
        return 0.7 + 0.5 * sin(phase * 2 * .pi - offset * .pi)
    }
}
