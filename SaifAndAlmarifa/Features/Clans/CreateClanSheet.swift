//
//  CreateClanSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Clans/CreateClanSheet.swift
//  شيت إنشاء عشيرة

import SwiftUI

struct CreateClanSheet: View {

    // ما يحتاج ViewModel مستقل — منطق بسيط
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedBadge: String = "shield"
    @State private var selectedColor: String = "FFD700"
    @State private var isSubmitting = false

    var onCreated: (Clan) -> Void

    // MARK: - Constants
    private let badges: [(key: String, icon: String)] = [
        ("shield", "shield.fill"),
        ("sword",  "bolt.shield.fill"),
        ("eagle",  "bird.fill"),
        ("lion",   "pawprint.fill"),
        ("crown",  "crown.fill"),
        ("star",   "star.fill"),
        ("flame",  "flame.fill"),
        ("flag",   "flag.fill")
    ]

    private let colors: [String] = [
        "FFD700", "60A5FA", "22C55E", "EF4444",
        "8B5CF6", "F97316", "EC4899", "14B8A6"
    ]

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 3
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSizes.Spacing.lg) {
                    preview
                    nameField
                    descField
                    badgePicker
                    colorPicker
                }
                .padding(AppSizes.Spacing.lg)
            }
            .background(GradientBackground.main)
            .withToast()
            .navigationTitle("عشيرة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }.foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isSubmitting { ProgressView().tint(AppColors.Default.goldPrimary) }
                        else { Text("إنشاء").foregroundStyle(isValid ? AppColors.Default.goldPrimary : .gray) }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
        }
        .dismissKeyboardOnTap()
    }

    // MARK: - المعاينة
    private var preview: some View {
        VStack(spacing: AppSizes.Spacing.sm) {
            ClanBadgeView(badge: selectedBadge, color: Color(hex: selectedColor), size: 80)
            Text(name.isEmpty ? "اسم العشيرة" : name)
                .font(.cairo(.bold, size: AppSizes.Font.title3))
                .foregroundStyle(.white)
            Text("تكلفة الإنشاء: 500 ذهب")
                .font(.cairo(.medium, size: AppSizes.Font.caption))
                .foregroundStyle(AppColors.Default.goldPrimary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSizes.Spacing.md)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            Text("الاسم")
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.7))
            AppTextField(placeholder: "اسم العشيرة", text: $name, icon: "textformat", style: .glass)
        }
    }

    private var descField: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            Text("الوصف (اختياري)")
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.7))
            AppTextField(placeholder: "ماذا تمثل عشيرتك؟", text: $description, icon: "text.alignright", style: .glass)
        }
    }

    private var badgePicker: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            Text("الشعار")
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.7))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(badges, id: \.key) { item in
                    Button {
                        HapticManager.selection()
                        selectedBadge = item.key
                    } label: {
                        Image(systemName: item.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(selectedBadge == item.key ? Color(hex: selectedColor) : .white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedBadge == item.key ? Color(hex: selectedColor).opacity(0.15) : .white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedBadge == item.key ? Color(hex: selectedColor) : .white.opacity(0.08), lineWidth: 1.5)
                            )
                    }
                }
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            Text("اللون")
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: AppSizes.Spacing.sm) {
                ForEach(colors, id: \.self) { hex in
                    Button {
                        HapticManager.selection()
                        selectedColor = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: selectedColor == hex ? 3 : 0)
                            )
                            .shadow(color: Color(hex: hex).opacity(0.5), radius: selectedColor == hex ? 8 : 0)
                    }
                }
            }
        }
    }

    // MARK: - الإرسال
    private func submit() async {
        guard isValid else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let clan = try await ClansService.shared.create(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                badge: selectedBadge,
                color: selectedColor
            )
            HapticManager.success()
            ToastManager.shared.success("تم إنشاء العشيرة")
            onCreated(clan)
            dismiss()
            // تحديث الرصيد
            _ = try? await AuthService.shared.getMe()
        } catch let e as APIError {
            HapticManager.error()
            ToastManager.shared.error(e.errorDescription ?? "فشل الإنشاء")
        } catch {
            HapticManager.error()
            ToastManager.shared.error("فشل الإنشاء")
        }
    }
}
