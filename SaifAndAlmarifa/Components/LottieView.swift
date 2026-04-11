//
//  LottieView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Components/LottieView.swift
//  مكوّن Lottie عام — قابل لإعادة الاستخدام في أي شاشة

import SwiftUI
import Lottie

// MARK: - Lottie Animation View
struct LottieView: View {

    // MARK: - Properties
    let name: String
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0
    var contentMode: UIView.ContentMode = .scaleAspectFit

    // MARK: - Body
    var body: some View {
        LottieViewRepresentable(
            name: name,
            loopMode: loopMode,
            speed: speed,
            contentMode: contentMode
        )
    }
}

// MARK: - UIKit Wrapper
private struct LottieViewRepresentable: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let speed: CGFloat
    let contentMode: UIView.ContentMode

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.loopMode = loopMode
        view.animationSpeed = speed
        view.contentMode = contentMode
        view.backgroundBehavior = .pauseAndRestore
        view.play()
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
