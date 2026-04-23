//
//  FloatingEmbers.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Components/FloatingEmbers.swift
//  جزيئات ذهبية تطفو في الخلفية — أجواء ملحمية

import SwiftUI

struct FloatingEmbers: View {
    var count: Int = 20

    @State private var embers: [Ember] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(embers) { ember in
                    Circle()
                        .fill(ember.color)
                        .frame(width: ember.size, height: ember.size)
                        .blur(radius: 1)
                        .opacity(ember.opacity)
                        .position(
                            x: ember.x * geo.size.width,
                            y: ember.y * geo.size.height
                        )
                }
            }
            .onAppear { spawn() }
        }
    }

    private func spawn() {
        embers = (0..<count).map { _ in Ember.random() }
        for i in embers.indices {
            animate(index: i)
        }
    }

    private func animate(index: Int) {
        let duration = Double.random(in: 6...12)
        let delay = Double.random(in: 0...3)

        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            embers[index].y = -0.1
            embers[index].x += Double.random(in: -0.1...0.1)
        }
        withAnimation(.easeIn(duration: 1.0).delay(delay + duration - 1)) {
            embers[index].opacity = 0
        }
    }
}

private struct Ember: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var size: CGFloat
    var color: Color
    var opacity: Double = 1

    static func random() -> Ember {
        let colors: [Color] = [
            Color(hex: "FFD700").opacity(0.4),
            Color(hex: "FF6B6B").opacity(0.25),
            Color(hex: "A78BFA").opacity(0.25),
            Color.white.opacity(0.2)
        ]
        return Ember(
            x: Double.random(in: 0...1),
            y: Double.random(in: 0.9...1.1),
            size: CGFloat.random(in: 2...5),
            color: colors.randomElement()!,
            opacity: Double.random(in: 0.4...0.9)
        )
    }
}
