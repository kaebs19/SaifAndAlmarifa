//
//  AvatarPickerSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Components/AvatarPickerSheet.swift
//  اختيار صورة شخصية — صور افتراضية + كاميرا + معرض

import SwiftUI
import PhotosUI

// MARK: - الصور الافتراضية
enum DefaultAvatar: String, CaseIterable, Identifiable {
    case castle     = "icon_castle"
    case crown      = "icon_crown"
    case sword      = "icon_sword"
    case shield     = "icon_shield"
    case medal      = "icon_medal"
    case gem        = "icon_gem"
    case swords     = "icon_swords_crossed"
    case swords2    = "icon_swords_crossed1"

    var id: String { rawValue }
}

// MARK: - نتيجة الاختيار
enum AvatarPickerResult {
    case defaultAvatar(String)
    case customImage(UIImage)
}

// MARK: - واجهة اختيار الصورة
struct AvatarPickerSheet: View {

    // MARK: - Properties
    var currentAvatarURL: String?
    let onSelect: (AvatarPickerResult) -> Void
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSizes.Spacing.xl) {
                    sourceButtons
                    defaultAvatarsSection
                }
                .padding(AppSizes.Spacing.lg)
            }
            .background(Color(hex: "0E1236"))
            .navigationTitle("الصورة الشخصية")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0E1236"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("إغلاق")
                            .font(.cairo(.semiBold, size: AppSizes.Font.body))
                            .foregroundStyle(AppColors.Default.goldPrimary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                onSelect(.customImage(image))
                dismiss()
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onSelect(.customImage(image))
                    dismiss()
                }
            }
        }
    }

    // MARK: أزرار المصدر (كاميرا + معرض)
    private var sourceButtons: some View {
        HStack(spacing: AppSizes.Spacing.md) {
            // الكاميرا
            Button {
                showCamera = true
            } label: {
                sourceLabel(icon: "camera.fill", title: "الكاميرا")
            }

            // المعرض
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                sourceLabel(icon: "photo.on.rectangle", title: "المعرض")
            }
        }
    }

    private func sourceLabel(icon: String, title: String) -> some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(AppColors.Default.goldPrimary)
            Text(title)
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: شبكة الصور الافتراضية
    private var defaultAvatarsSection: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.md) {
            Text("أو اختر صورة افتراضية")
                .font(.cairo(.semiBold, size: AppSizes.Font.bodyLarge))
                .foregroundStyle(.white)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSizes.Spacing.md), count: 4),
                spacing: AppSizes.Spacing.md
            ) {
                ForEach(DefaultAvatar.allCases) { avatar in
                    Button {
                        HapticManager.selection()
                        onSelect(.defaultAvatar(avatar.rawValue))
                        dismiss()
                    } label: {
                        Image(avatar.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .padding(AppSizes.Spacing.sm)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        AppColors.Default.goldPrimary.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    AvatarPickerSheet { result in
        print(result)
    }
}
