//
//  CountryPicker.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Components/Auth/CountryPicker.swift
//  اختيار الدولة — Auto-detect + قائمة يدوية

import SwiftUI

// MARK: - نموذج الدولة
struct Country: Identifiable, Hashable {
    let id: String   // ISO code: "SA", "EG", ...
    let flag: String
    let nameAr: String
}

// MARK: - قائمة الدول
enum CountryList {

    static let all: [Country] = [
        // الخليج
        Country(id: "SA", flag: "🇸🇦", nameAr: "السعودية"),
        Country(id: "AE", flag: "🇦🇪", nameAr: "الإمارات"),
        Country(id: "KW", flag: "🇰🇼", nameAr: "الكويت"),
        Country(id: "QA", flag: "🇶🇦", nameAr: "قطر"),
        Country(id: "BH", flag: "🇧🇭", nameAr: "البحرين"),
        Country(id: "OM", flag: "🇴🇲", nameAr: "عُمان"),
        // عربي
        Country(id: "EG", flag: "🇪🇬", nameAr: "مصر"),
        Country(id: "JO", flag: "🇯🇴", nameAr: "الأردن"),
        Country(id: "IQ", flag: "🇮🇶", nameAr: "العراق"),
        Country(id: "LB", flag: "🇱🇧", nameAr: "لبنان"),
        Country(id: "SY", flag: "🇸🇾", nameAr: "سوريا"),
        Country(id: "PS", flag: "🇵🇸", nameAr: "فلسطين"),
        Country(id: "YE", flag: "🇾🇪", nameAr: "اليمن"),
        Country(id: "LY", flag: "🇱🇾", nameAr: "ليبيا"),
        Country(id: "TN", flag: "🇹🇳", nameAr: "تونس"),
        Country(id: "DZ", flag: "🇩🇿", nameAr: "الجزائر"),
        Country(id: "MA", flag: "🇲🇦", nameAr: "المغرب"),
        Country(id: "SD", flag: "🇸🇩", nameAr: "السودان"),
        // أخرى
        Country(id: "TR", flag: "🇹🇷", nameAr: "تركيا"),
        Country(id: "US", flag: "🇺🇸", nameAr: "أمريكا"),
        Country(id: "GB", flag: "🇬🇧", nameAr: "بريطانيا"),
        Country(id: "DE", flag: "🇩🇪", nameAr: "ألمانيا"),
        Country(id: "FR", flag: "🇫🇷", nameAr: "فرنسا"),
    ]

    /// اكتشاف الدولة من إعدادات الجهاز
    static func detect() -> Country {
        let regionCode = Locale.current.region?.identifier ?? "SA"
        return all.first { $0.id == regionCode } ?? all[0]
    }
}

// MARK: - زر اختيار الدولة
struct CountryPickerButton: View {
    @Binding var selectedCountry: Country
    @State private var showPicker = false

    var body: some View {
        Button { showPicker = true } label: {
            HStack(spacing: AppSizes.Spacing.sm) {
                Image(systemName: "globe")
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: AppSizes.Icon.medium)

                Spacer()

                Text(selectedCountry.flag + " " + selectedCountry.nameAr)
                    .font(.cairo(.medium, size: AppSizes.Font.body))
                    .foregroundStyle(.white)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(AppSizes.Spacing.md)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.medium)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showPicker) {
            CountryPickerSheet(selected: $selectedCountry)
        }
    }
}

// MARK: - Sheet اختيار الدولة (ثيم داكن)
struct CountryPickerSheet: View {
    @Binding var selected: Country
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss

    private var filtered: [Country] {
        if search.isEmpty { return CountryList.all }
        return CountryList.all.filter { $0.nameAr.contains(search) || $0.id.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered) { country in
                        Button {
                            selected = country
                            HapticManager.selection()
                            dismiss()
                        } label: {
                            HStack(spacing: AppSizes.Spacing.md) {
                                Text(country.flag)
                                    .font(.system(size: 30))

                                Text(country.nameAr)
                                    .font(.cairo(.medium, size: AppSizes.Font.bodyLarge))
                                    .foregroundStyle(.white)

                                Spacer()

                                if country.id == selected.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppColors.Default.goldPrimary)
                                }
                            }
                            .padding(.horizontal, AppSizes.Spacing.lg)
                            .padding(.vertical, AppSizes.Spacing.md)
                        }

                        if country.id != filtered.last?.id {
                            Divider()
                                .overlay(.white.opacity(0.08))
                                .padding(.leading, 70)
                        }
                    }
                }
                .padding(.top, AppSizes.Spacing.sm)
            }
            .background(Color(hex: "0E1236"))
            .searchable(text: $search, prompt: "ابحث عن دولة")
            .navigationTitle("اختر الدولة")
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
    }
}

#Preview {
    ZStack {
        GradientBackground.main
        CountryPickerButton(selectedCountry: .constant(CountryList.detect()))
            .padding()
    }
}
