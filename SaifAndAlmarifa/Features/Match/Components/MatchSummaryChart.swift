//
//  MatchSummaryChart.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/MatchSummaryChart.swift
//  ملخّص أداء كل سؤال في المباراة
//

import SwiftUI

struct MatchSummaryChart: View {
    let history: [QuestionStat]

    private var totals: (correct: Int, closest: Int, wrong: Int, points: Int) {
        var c = 0, cl = 0, w = 0, p = 0
        for s in history {
            p += s.pointsAwarded
            if s.isCorrect { c += 1 }
            else if s.isClosest { cl += 1 }
            else { w += 1 }
        }
        return (c, cl, w, p)
    }

    private var avgTime: Double? {
        let times = history.compactMap(\.timeMs)
        guard !times.isEmpty else { return nil }
        return Double(times.reduce(0, +)) / Double(times.count) / 1000.0
    }

    private var fastestTime: Double? {
        let times = history.compactMap(\.timeMs)
        guard let min = times.min() else { return nil }
        return Double(min) / 1000.0
    }

    private var slowestTime: Double? {
        let times = history.compactMap(\.timeMs)
        guard let max = times.max() else { return nil }
        return Double(max) / 1000.0
    }

    private var accuracy: Int {
        guard !history.isEmpty else { return 0 }
        let correctCount = history.filter { $0.isCorrect }.count
        return Int(Double(correctCount) / Double(history.count) * 100)
    }

    private var longestStreak: Int {
        var best = 0
        var current = 0
        for s in history {
            if s.isCorrect {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    var body: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            // Title
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                Text("ملخّص الأداء")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                Spacer()
                if let avg = avgTime {
                    Text("متوسط: \(String(format: "%.1f", avg))s")
                        .font(.cairo(.medium, size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                }
            }

            // إجمالي
            HStack(spacing: 8) {
                summaryChip(icon: "checkmark.seal.fill",
                            value: totals.correct, color: AppColors.Default.success)
                summaryChip(icon: "scope",
                            value: totals.closest, color: Color(hex: "F59E0B"))
                summaryChip(icon: "xmark.octagon.fill",
                            value: totals.wrong, color: AppColors.Default.error)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .black))
                    Text("\(totals.points)")
                        .font(.poppins(.black, size: 14))
                        .monospacedDigit()
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FFE55C"), Color(hex: "FFB800")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }

            // Per-question dots
            HStack(spacing: 6) {
                ForEach(history) { s in
                    questionDot(s)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ✨ إحصائيات تفصيلية (Stage 5+)
            statsGrid
        }
        .padding(AppSizes.Spacing.md)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statsGrid: some View {
        VStack(spacing: 6) {
            Divider().background(.white.opacity(0.08))

            HStack(spacing: 8) {
                statBox(icon: "scope", label: "الدقّة", value: "\(accuracy)%",
                        color: AppColors.Default.success)
                if let fast = fastestTime {
                    statBox(icon: "bolt.fill", label: "أسرع",
                            value: String(format: "%.1fs", fast),
                            color: Color(hex: "FFD700"))
                }
                if let slow = slowestTime {
                    statBox(icon: "tortoise.fill", label: "أبطأ",
                            value: String(format: "%.1fs", slow),
                            color: Color(hex: "94A3B8"))
                }
                if longestStreak >= 2 {
                    statBox(icon: "flame.fill", label: "أطول سلسلة",
                            value: "×\(longestStreak)",
                            color: Color(hex: "F97316"))
                }
            }
        }
    }

    private func statBox(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(color)
                Text(label)
                    .font(.cairo(.medium, size: 9))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Text(value)
                .font(.poppins(.black, size: 12))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func summaryChip(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.poppins(.black, size: 13))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    private func questionDot(_ s: QuestionStat) -> some View {
        let color: Color
        let icon: String
        if s.isCorrect {
            color = s.isFastest ? Color(hex: "FFD700") : AppColors.Default.success
            icon = s.isFastest ? "bolt.fill" : "checkmark"
        } else if s.isClosest {
            color = Color(hex: "F59E0B"); icon = "scope"
        } else {
            color = AppColors.Default.error; icon = "xmark"
        }

        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.4), color.opacity(0.15)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 26, height: 26)
            Circle()
                .stroke(color.opacity(0.6), lineWidth: 1)
                .frame(width: 26, height: 26)
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(color)
        }
        .overlay(alignment: .topTrailing) {
            // مؤشّر phase (شعرة صغيرة فوق)
            if s.phase == .battle {
                Circle()
                    .fill(Color(hex: "EF4444"))
                    .frame(width: 5, height: 5)
                    .offset(x: 2, y: -2)
            }
        }
    }
}
