//
//  ContactUsView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Content/ContactUsView.swift
//  صفحة اتصل بنا (بيانات تواصل)

import SwiftUI

// MARK: - صفحة اتصل بنا
struct ContactUsView: View {

    var onBack: () -> Void = {}
    @StateObject private var viewModel = ContentPageViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSizes.Spacing.lg) {
                header

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.Default.goldPrimary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let data = viewModel.content?.value {
                    contactRows(data)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.cairo(.regular, size: AppSizes.Font.body))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(AppSizes.Spacing.lg)
        }
        .background(GradientBackground.main)
        .task { await viewModel.load(.contactUs) }
    }

    private var header: some View {
        ZStack {
            Text(AppStrings.Settings.about)
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(AppColors.Default.goldPrimary)
            HStack {
                Spacer()
                AuthBackButton(action: onBack)
            }
        }
    }

    // MARK: صفوف بيانات التواصل
    private func contactRows(_ data: ContentValue) -> some View {
        VStack(spacing: 0) {
            if let email = data.email {
                contactRow(icon: "envelope.fill", label: "البريد", value: email, url: "mailto:\(email)")
                divider
            }
            if let phone = data.phone {
                contactRow(icon: "phone.fill", label: "الهاتف", value: phone, url: "tel:\(phone)")
                divider
            }
            if let website = data.website {
                contactRow(icon: "globe", label: "الموقع", value: website, url: website)
                divider
            }
            if let twitter = data.twitter {
                contactRow(icon: "at", label: "تويتر", value: twitter, url: "https://twitter.com/\(twitter.replacingOccurrences(of: "@", with: ""))")
                divider
            }
            if let instagram = data.instagram {
                contactRow(icon: "camera.fill", label: "انستقرام", value: instagram, url: "https://instagram.com/\(instagram.replacingOccurrences(of: "@", with: ""))")
            }
        }
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func contactRow(icon: String, label: String, value: String, url: String) -> some View {
        Button {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        } label: {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .frame(width: 28)
                Text(label)
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text(value)
                    .font(.poppins(.regular, size: AppSizes.Font.body))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(.horizontal, AppSizes.Spacing.md)
            .padding(.vertical, AppSizes.Spacing.sm)
        }
    }

    private var divider: some View {
        Divider().overlay(.white.opacity(0.06))
    }
}
