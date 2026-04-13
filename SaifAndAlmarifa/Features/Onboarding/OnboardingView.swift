//
//  OnboardingView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import SwiftUI

// MARK: - بيانات الصفحة
struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - شاشة الترحيب (أول مرة فقط)
struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(icon: "icon_swords_crossed", title: "تحدى أصدقاءك", subtitle: "ادخل معارك فكرية مباشرة ضد لاعبين حقيقيين", color: AppColors.Default.goldPrimary),
        OnboardingPage(icon: "icon_castle", title: "ابنِ قلعتك", subtitle: "أجب صح وارتفع بمستواك واهدم قلاع خصومك", color: AppColors.Default.error),
        OnboardingPage(icon: "icon_gem", title: "اجمع الجواهر", subtitle: "اربح جواهر واستخدمها لشراء أدوات وقوى خاصة", color: AppColors.Default.success),
    ]

    var body: some View {
        ZStack {
            GradientBackground.main

            VStack(spacing: AppSizes.Spacing.xl) {
                Spacer()

                // المحتوى
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        pageContent(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 350)

                // المؤشرات
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? AppColors.Default.goldPrimary : .white.opacity(0.2))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }

                Spacer()

                // الأزرار
                VStack(spacing: AppSizes.Spacing.md) {
                    if currentPage < pages.count - 1 {
                        GradientButton(title: "التالي", colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary]) {
                            withAnimation { currentPage += 1 }
                            HapticManager.light()
                        }
                        Button { complete() } label: {
                            Text("تخطي").font(.cairo(.medium, size: AppSizes.Font.body)).foregroundStyle(.white.opacity(0.5))
                        }
                    } else {
                        GradientButton(title: "ابدأ المعركة!", icon: "icon_swords_crossed", colors: [AppColors.Default.goldLight, AppColors.Default.goldPrimary]) {
                            complete()
                        }
                    }
                }
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.bottom, AppSizes.Spacing.xxl)
            }
        }
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: AppSizes.Spacing.xl) {
            Image(page.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: page.color.opacity(0.5), radius: 20)

            Text(page.title)
                .font(.cairo(.black, size: AppSizes.Font.title1))
                .foregroundStyle(AppColors.Default.goldPrimary)

            Text(page.subtitle)
                .font(.cairo(.regular, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSizes.Spacing.xl)
        }
    }

    private func complete() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        HapticManager.success()
        onComplete()
    }

    static var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: "onboarding_completed")
    }
}
