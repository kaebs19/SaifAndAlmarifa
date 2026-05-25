//
//  QuickChatComponents.swift
//  SaifAndAlmarifa
//
//  Sheet لاختيار preset/emoji + فقاعة تطفو فوق رأس القلعة
//

import SwiftUI

// MARK: - Quick Chat Sheet

struct QuickChatSheet: View {
    enum Tab { case messages, emojis }

    @Binding var selectedTab: Tab
    let onSendPreset: (QuickMessagePreset) -> Void
    let onSendEmoji: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            handleBar
            tabSwitcher
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.top, AppSizes.Spacing.sm)
            content
                .padding(.horizontal, AppSizes.Spacing.lg)
                .padding(.top, AppSizes.Spacing.md)
                .padding(.bottom, AppSizes.Spacing.lg)
        }
        .background(Color(hex: "1A1410"))
    }

    private var handleBar: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 40, height: 4)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    private var tabSwitcher: some View {
        HStack(spacing: 8) {
            tabButton("💬 رسائل", isOn: selectedTab == .messages) {
                selectedTab = .messages
            }
            tabButton("😀 إيموجي", isOn: selectedTab == .emojis) {
                selectedTab = .emojis
            }
        }
    }

    private func tabButton(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.cairo(.semiBold, size: AppSizes.Font.body))
                .foregroundStyle(isOn ? Color.black : Color.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isOn ? AppColors.Default.goldPrimary : Color.white.opacity(0.06))
                )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .messages: presetGrid
        case .emojis:   emojiGrid
        }
    }

    private var presetGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(QuickMessagePreset.allCases, id: \.self) { preset in
                Button {
                    onSendPreset(preset)
                    onDismiss()
                } label: {
                    Text(preset.text)
                        .font(.cairo(.semiBold, size: AppSizes.Font.body))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.Default.goldPrimary.opacity(0.25), lineWidth: 1)
                        )
                }
            }
        }
    }

    private var emojiGrid: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 4)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(QuickEmojiCatalog.all, id: \.self) { emoji in
                Button {
                    onSendEmoji(emoji)
                    onDismiss()
                } label: {
                    Text(emoji)
                        .font(.system(size: 36))
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                        )
                }
            }
        }
    }
}

// MARK: - Floating Message Bubble

struct QuickMessageBubble: View {
    let message: QuickMessage
    let isMine: Bool

    var body: some View {
        Group {
            if message.kind == .emoji {
                Text(message.value)
                    .font(.system(size: 38))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            } else {
                Text(message.displayText)
                    .font(.cairo(.bold, size: AppSizes.Font.caption))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isMine
                                  ? AppColors.Default.goldPrimary.opacity(0.92)
                                  : Color(hex: "1A1410").opacity(0.95))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isMine ? Color.white.opacity(0.25) : AppColors.Default.goldPrimary.opacity(0.6),
                                lineWidth: 1.2
                            )
                    )
                    .foregroundStyle(isMine ? Color.black : Color.white)
            }
        }
        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 3)
        .transition(.scale(scale: 0.7).combined(with: .opacity))
    }
}
