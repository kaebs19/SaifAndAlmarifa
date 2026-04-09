//
//  AvatarView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 08/04/2026.
//
//  Path: SaifAndAlmarifa/Components/AvatarView.swift
//  مكون الصورة الشخصية

import SwiftUI

struct AvatarView: View {
    var imageURL: String? = nil
    var size: CGFloat = AppSizes.Avatar.medium
    var showOnlineIndicator: Bool = false
    var isOnline: Bool = false
    var onTap: (() -> Void)? = nil  // ✅ جديد — اختياري
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let url = imageURL, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholderImage
            }
            
            if showOnlineIndicator {
                Circle()
                    .fill(isOnline ? Color.green : Color.gray)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .contentShape(Circle())
        // ✅ Tap فقط لو onTap موجود
        .onTapGesture {
            guard let onTap else { return }
            onTap()
        }
    }
    
    private var placeholderImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.5, height: size * 0.5)
                    .foregroundStyle(Color.gray)
            )
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 20) {
        AvatarView(size: AppSizes.Avatar.small)
        AvatarView(size: AppSizes.Avatar.medium, showOnlineIndicator: true, isOnline: true)
        AvatarView(size: AppSizes.Avatar.large, showOnlineIndicator: true, isOnline: false)
    }
    .padding()
}
