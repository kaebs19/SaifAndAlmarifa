//
//  SettingsRow.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/SettingsRow.swift
//  مكون صف الإعدادات | Settings Row Component

import SwiftUI

// MARK: - Settings Row
/// صف واحد في قائمة الإعدادات مع أيقونة ملونة وعنوان وقيمة اختيارية
struct SettingsRow: View {
    
    // MARK: - Properties
    let icon: String
    let title: String
    var value: String? = nil
    var iconColor: Color = AppColors.Default.primary
    var showChevron: Bool = true
    var action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSizes.Spacing.md) {
                
                // أيقونة في دائرة ملونة
                iconView
                
                // العنوان
                Text(title)
                    .font(.cairo(.regular, size: AppSizes.Font.bodyLarge))
                    .foregroundStyle(AppColors.Default.textPrimary)
                
                Spacer()
                
                // القيمة (اختيارية)
                if let value = value {
                    Text(value)
                        .font(.cairo(.regular, size: AppSizes.Font.body))
                        .foregroundStyle(AppColors.Default.textSecondary)
                }
                
                // سهم التنقل
                if showChevron {
                    RTLChevron()
                }
            }
            .padding(.vertical, AppSizes.Spacing.sm)
            .padding(.horizontal, AppSizes.Spacing.md)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Icon View
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.12))
                .frame(width: 40, height: 40)
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - Settings Section
/// قسم في الإعدادات مع عنوان ومحتوى
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Spacing.xs) {
            // عنوان القسم
            Text(title)
                .font(.cairo(.semiBold, size: AppSizes.Font.caption))
                .foregroundStyle(AppColors.Default.textSecondary)
                .padding(.horizontal, AppSizes.Spacing.lg)
            
            // محتوى القسم في بطاقة
            VStack(spacing: 0) {
                content()
            }
            .background(AppColors.Default.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .padding(.horizontal, AppSizes.Spacing.md)
        }
    }
}

// MARK: - Settings Divider
/// خط فاصل بين صفوف الإعدادات
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 68) // بعد الأيقونة
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: AppSizes.Spacing.lg) {
            SettingsSection(title: "ACCOUNT") {
                SettingsRow(icon: "bell", title: "Notifications", iconColor: .orange) {}
                SettingsDivider()
                SettingsRow(icon: "shield", title: "Privacy & Security", iconColor: AppColors.Default.primary) {}
            }
            
            SettingsSection(title: "PREFERENCES") {
                SettingsRow(icon: "circle.lefthalf.filled", title: "Appearance", value: "Light", iconColor: AppColors.Default.primary) {}
                SettingsDivider()
                SettingsRow(icon: "globe", title: "Language", value: "English", iconColor: AppColors.Default.primary) {}
            }
        }
        .padding(.top)
    }
    .background(AppColors.Default.background)
}
