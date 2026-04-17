//
//  SkeletonView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Components/SkeletonView.swift
//  مكوّن Skeleton/Shimmer لعرض placeholders أثناء التحميل

import SwiftUI

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .white.opacity(0),
                            .white.opacity(0.15),
                            .white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: phase * geo.size.width * 2)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Skeleton Box
struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.white.opacity(0.08))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - صف Skeleton للعضو / العشيرة
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: AppSizes.Spacing.sm) {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 44, height: 44)
                .shimmer()
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBox(width: 120, height: 12)
                SkeletonBox(width: 80, height: 10)
            }
            Spacer()
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, AppSizes.Spacing.sm)
    }
}

// MARK: - قائمة Skeleton (عدد صفوف)
struct SkeletonList: View {
    var count: Int = 6

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonRow()
                Divider().overlay(.white.opacity(0.05)).padding(.leading, 60)
            }
        }
    }
}

// MARK: - نقاط "يكتب الآن"
struct TypingDots: View {
    @State private var scale: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(AppColors.Default.goldPrimary.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .scaleEffect(scale[i])
            }
        }
        .onAppear { animate() }
    }

    private func animate() {
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.2)
            ) {
                scale[i] = 1.6
            }
        }
    }
}
