//
//  MainTabBar.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//

import SwiftUI

// MARK: - شريط التنقل السفلي
struct MainTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    HapticManager.selection()
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.title)
                            .font(.cairo(.medium, size: 11))
                    }
                    .foregroundStyle(selectedTab == tab
                        ? AppColors.Default.goldPrimary
                        : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, AppSizes.Spacing.sm)
        .padding(.bottom, AppSizes.Spacing.xs)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.Default.goldPrimary.opacity(0.2))
                .frame(height: 0.5)
        }
    }
}
