//
//  AppColors.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//

//  Path: SaifAndAlmarifa/Core/AppColors.swift
//  المسؤول عن إدارة ألوان التطبيق - هوية لعبة سيف المعرفة
//  ثيم: ملكي ذهبي مع خلفيات كحلية/بنفسجية فاخرة

import SwiftUI

// MARK: - App Colors
struct AppColors {
    
    // MARK: - Primary Gold Palette
    /// الذهبي الأساسي - الأزرار الرئيسية والشعار
    static let goldPrimary = Color("GoldPrimary")
    /// الذهبي الداكن - للتدرجات وحالات التفاعل
    static let goldDark = Color("GoldDark")
    /// الذهبي الفاتح - للتوهج والإبراز
    static let goldLight = Color("GoldLight")
    /// الذهبي العتيق - للوضع الفاتح
    static let goldAntique = Color("GoldAntique")
    
    // MARK: - Background Colors
    static let background = Color("Background")
    static let cardBackground = Color("CardBackground")
    static let cardElevated = Color("CardElevated")
    static let inputBackground = Color("InputBackground")
    
    // MARK: - Text Colors
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textMuted = Color("TextMuted")
    static let textInverted = Color("TextInverted")
    
    // MARK: - Semantic Colors (حالات اللعبة)
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    static let info = Color("Info")
    
    // MARK: - Border & Divider
    static let border = Color("Border")
    static let borderGold = Color("BorderGold")
    static let divider = Color("Divider")
    
    
    // MARK: - Default Colors (Fallback - Adaptive)
    /// ألوان احتياطية تتكيف مع Light/Dark Mode
    /// تستخدم قبل إضافة الألوان في Assets.xcassets
    struct Default {
        
        // MARK: Gold Palette
        static let goldPrimary = Color(light: "C9A227", dark: "FFD700")
        static let goldDark = Color(light: "B8860B", dark: "FFA500")
        static let goldLight = Color(light: "DAA520", dark: "FFE55C")
        static let goldAntique = Color(light: "8B6914", dark: "C9A961")

        // MARK: Semantic Aliases (للاستخدام العام في الأزرار والعناصر)
        /// اللون الأساسي (Alias للذهبي الأساسي)
        static let primary = goldPrimary
        /// اللون الثانوي (Alias للذهبي الداكن)
        static let secondary = goldDark
        /// لون التمييز (Alias للذهبي الفاتح)
        static let accent = goldLight
        
        // MARK: Backgrounds
        /// الخلفية الرئيسية
        static let background = Color(light: "F8F5EC", dark: "0A0E27")
        /// خلفية البطاقات والـ containers
        static let cardBackground = Color(light: "FFFFFF", dark: "15193D")
        /// خلفية مرتفعة (للعناصر اللي فوق الكروت)
        static let cardElevated = Color(light: "FAF3E0", dark: "1A1147")
        /// خلفية حقول الإدخال
        static let inputBackground = Color(light: "F4EFE0", dark: "0A0E27")
        
        // MARK: Text
        static let textPrimary = Color(light: "0A0E27", dark: "FFFFFF")
        static let textSecondary = Color(light: "5D4E3C", dark: "C9A961")
        static let textMuted = Color(light: "9B8E7A", dark: "8B8FA8")
        static let textInverted = Color(light: "FFFFFF", dark: "0A0E27")
        
        // MARK: Semantic
        static let success = Color(light: "16A34A", dark: "4ADE80")
        static let warning = Color(light: "F59E0B", dark: "FBBF24")
        static let error = Color(light: "DC2626", dark: "EF4444")
        static let info = Color(light: "2563EB", dark: "60A5FA")
        
        // MARK: Borders
        static let border = Color(light: "E5DCC0", dark: "2A2F4F")
        static let borderGold = Color(light: "C9A227", dark: "FFD700")
        static let divider = Color(light: "EFE6CC", dark: "1F2347")
    }
    
    
    // MARK: - Game-Specific Colors (ثابتة - ما تتغير مع الثيم)
    
    /// ألوان حالات القلعة 🏰
    struct Castle {
        static let healthy = Color(hex: "FFD700")    // سليمة
        static let damaged = Color(hex: "FB923C")    // متضررة
        static let critical = Color(hex: "EF4444")   // حرجة
        static let destroyed = Color(hex: "6B7280")  // مدمرة
    }
    
    /// ألوان رتب اللاعبين 🏆
    struct Tier {
        static let bronze = Color(hex: "CD7F32")    // برونزي
        static let silver = Color(hex: "C0C0C0")    // فضي
        static let gold = Color(hex: "FFD700")      // ذهبي
        static let platinum = Color(hex: "E5E4E2")  // بلاتيني
        static let diamond = Color(hex: "B9F2FF")   // ماسي
    }
    
    /// تدرجات جاهزة للاستخدام
    struct Gradients {
        /// التدرج الذهبي الرئيسي - للأزرار والشعار
        static let gold = LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// تدرج الخلفية الرئيسية - كحلي إلى بنفسجي
        static let background = LinearGradient(
            colors: [Color(hex: "0A0E27"), Color(hex: "1A1147")],
            startPoint: .top,
            endPoint: .bottom
        )
        
        /// تدرج Battle Pass - بنفسجي إلى ذهبي
        static let battlePass = LinearGradient(
            colors: [Color(hex: "1A1147"), Color(hex: "FFA500")],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        /// تدرج النصر 🏆
        static let victory = LinearGradient(
            colors: [Color(hex: "FFE55C"), Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .top,
            endPoint: .bottom
        )
        
        /// تدرج الهزيمة 💀
        static let defeat = LinearGradient(
            colors: [Color(hex: "6B7280"), Color(hex: "374151")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}



// MARK: - Usage Examples
/*
 ═══════════════════════════════════════════════════════════════
 أمثلة الاستخدام
 ═══════════════════════════════════════════════════════════════
 
 // 1. الألوان الأساسية (Default - تتكيف تلقائياً)
 Text("سيف المعرفة")
     .foregroundStyle(AppColors.Default.goldPrimary)
     .font(.system(size: 32, weight: .bold))
 
 // 2. زر رئيسي بتدرج ذهبي
 Button("ابدأ المعركة") { }
     .padding()
     .background(AppColors.Gradients.gold)
     .foregroundStyle(.black)
     .clipShape(RoundedRectangle(cornerRadius: 16))
 
 // 3. خلفية الشاشة الرئيسية
 ZStack {
     AppColors.Gradients.background
         .ignoresSafeArea()
     // المحتوى...
 }
 
 // 4. حالة قلعة
 Image("icon_castle")
     .renderingMode(.template)
     .foregroundStyle(AppColors.Castle.healthy)  // أو damaged, critical
 
 // 5. رتبة لاعب
 Image("icon_medal")
     .renderingMode(.template)
     .foregroundStyle(AppColors.Tier.gold)
 
 // 6. كرت بحدود ذهبية
 VStack {
     Text("معركة الأربعة")
 }
 .padding()
 .background(AppColors.Default.cardBackground)
 .overlay(
     RoundedRectangle(cornerRadius: 20)
         .stroke(AppColors.Default.borderGold, lineWidth: 1.5)
 )
 
 // 7. نص ثانوي ذهبي خافت
 Text("المستوى 12 • محارب")
     .foregroundStyle(AppColors.Default.textSecondary)
     .font(.system(size: 14))
 
 ═══════════════════════════════════════════════════════════════
*/
