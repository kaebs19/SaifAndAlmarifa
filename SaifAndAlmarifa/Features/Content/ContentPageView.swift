//
//  ContentPageView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Content/ContentPageView.swift
//  عرض صفحة محتوى نصي (سياسة/شروط/حول)

import SwiftUI

// MARK: - صفحة محتوى نصي
struct ContentPageView: View {

    let pageKey: ContentPageKey
    let title: String
    var onBack: () -> Void = {}

    @StateObject private var viewModel = ContentPageViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSizes.Spacing.lg) {
                header
                contentBody
            }
            .padding(AppSizes.Spacing.lg)
        }
        .background(GradientBackground.main)
        .task { await viewModel.load(pageKey) }
    }

    // MARK: الهيدر
    private var header: some View {
        ZStack {
            Text(title)
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                AuthBackButton(action: onBack)
            }
        }
    }

    // MARK: المحتوى
    @ViewBuilder
    private var contentBody: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(AppColors.Default.goldPrimary)
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else if let data = viewModel.content {
            Text(data.value.content ?? "")
                .font(.cairo(.regular, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppSizes.Spacing.md) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            Text(message)
                .font(.cairo(.regular, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.5))
            Button("إعادة المحاولة") {
                Task { await viewModel.load(pageKey) }
            }
            .font(.cairo(.semiBold, size: AppSizes.Font.body))
            .foregroundStyle(AppColors.Default.goldPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
