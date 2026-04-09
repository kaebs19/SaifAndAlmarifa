//
//  AppSizes.swift
//  DatingHala
//
//  Created by Mohammed Saleh on 25/01/2026.
//

//  Path: DatingHala/Core/AppSizes.swift
//  المسؤول عن إدارة الأحجام والمسافات في التطبيق

import SwiftUI

// MARK: - App Sizes
struct AppSizes {
    
    /// MARK: - Spacing (المسافات)
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    /// MARK: - Font Sizes (أحجام الخطوط)
    struct Font {
        static let caption: CGFloat = 12
        static let body: CGFloat = 14
        static let bodyLarge: CGFloat = 16
        static let title3: CGFloat = 18
        static let title2: CGFloat = 22
        static let title1: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }
    
    /// MARK: - Corner Radius (الحواف)
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999 // للدوائر الكاملة
    }
    
    /// MARK: - Icon Sizes (أحجام الأيقونات)
    struct Icon {
        static let small: CGFloat = 16
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let xl: CGFloat = 48
    }
    
    /// MARK: - Button Heights (ارتفاعات الأزرار)
    struct Button {
        static let small: CGFloat = 36
        static let medium: CGFloat = 44
        static let large: CGFloat = 52
    }
    
    /// MARK: - Avatar Sizes (أحجام الصور الشخصية)
    struct Avatar {
        static let small: CGFloat = 32
        static let medium: CGFloat = 48
        static let large: CGFloat = 64
        static let xl: CGFloat = 100
    }
    
    /*
    // MARK: - Screen
    struct Screen {
        static let width = UIScreen.main.bounds.width
        static let height = UIScreen.main.bounds.height
    }
     */
}

// MARK: - Usage Examples
/*
 استخدام الأحجام:
 
 VStack(spacing: AppSizes.Spacing.md) {
     Text("عنوان")
         .font(.cairo(.bold, size: AppSizes.Font.title1))
     
     Image(systemName: "heart.fill")
         .frame(width: AppSizes.Icon.large, height: AppSizes.Icon.large)
 }
 .padding(AppSizes.Spacing.lg)
 
 Button("تسجيل الدخول") { }
     .frame(height: AppSizes.Button.large)
     .cornerRadius(AppSizes.Radius.medium)
 */
