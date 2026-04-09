//
//  AppTheme.swift
//  DatingHala
//
//  Created by Mohammed Saleh on 26/01/2026.
//

//  Path: SaifAndAlmarifa/Core/AppTheme.swift
//  المسؤول عن إدارة ثيم التطبيق (Light/Dark/System)

import SwiftUI
import Combine

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var title: String {
        switch self {
        case .system: return "تلقائي"
        case .light: return "فاتح"
        case .dark: return "داكن"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
    
    // Singleton
    static let shared = ThemeManager()
    
    // MARK: - Published
    @Published var currentTheme: ThemeMode {
        didSet {
            saveTheme()
        }
    }
    
    // MARK: - Private
    private let themeKey = "appTheme"
    
    private init() {
        // تحميل الثيم المحفوظ
        let savedTheme = UserDefaults.standard.string(forKey: themeKey) ?? ThemeMode.system.rawValue
        self.currentTheme = ThemeMode(rawValue: savedTheme) ?? .system
    }
    
    // MARK: - Methods
    func setTheme(_ theme: ThemeMode) {
        currentTheme = theme
    }
    
    func toggleTheme() {
        switch currentTheme {
        case .system:
            currentTheme = .light
        case .light:
            currentTheme = .dark
        case .dark:
            currentTheme = .system
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    // MARK: - Color Scheme
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}

// MARK: - Theme View Modifier
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    func applyTheme() -> some View {
        self.modifier(ThemeModifier())
    }
}

// MARK: - Theme Picker View (Component)
struct ThemePicker: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        Picker("المظهر", selection: $themeManager.currentTheme) {
            ForEach(ThemeMode.allCases, id: \.self) { theme in
                Label(theme.title, systemImage: theme.icon)
                    .tag(theme)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Theme Toggle Button (Component)
struct ThemeToggleButton: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                themeManager.toggleTheme()
            }
        } label: {
            Image(systemName: themeManager.currentTheme.icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.Default.textPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        ThemePicker()
        ThemeToggleButton()
        
        Text("مثال على النص")
            .foregroundStyle(AppColors.Default.textPrimary)
    }
    .padding()
    .background(AppColors.Default.background)
    .applyTheme()
}

// MARK: - Usage in App
/*
 في DatingHalaApp.swift:
 
 @main
 struct DatingHalaApp: App {
     @StateObject private var themeManager = ThemeManager.shared
     
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .applyTheme()
         }
     }
 }
 
 أو في أي View:
 
 struct SettingsView: View {
     var body: some View {
         Form {
             Section("المظهر") {
                 ThemePicker()
             }
         }
     }
 }
 */
