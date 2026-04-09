//
//  LoadingView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//

//  Path: SaifAndAlmarifa/Components/LoadingView.swift
//  مكون شاشة التحميل

import SwiftUI

struct LoadingView: View {
    var message: String? = nil
    
    var body: some View {
        VStack(spacing: AppSizes.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.Default.primary))
                .scaleEffect(1.5)
            
            if let message = message {
                Text(message)
                    .font(.cairo(.regular, size: AppSizes.Font.body))
                    .foregroundStyle(AppColors.Default.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Loading Modifier
struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    var message: String? = nil
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isLoading {
                LoadingView(message: message)
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Bool, message: String? = nil) -> some View {
        self.modifier(LoadingModifier(isLoading: isLoading, message: message))
    }
}

// MARK: - Preview
#Preview {
    Text("محتوى الشاشة")
        .loading(true, message: "جاري التحميل...")
}
