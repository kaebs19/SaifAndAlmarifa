//
//  NotificationsView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    private let network: NetworkClient = NetworkManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // الهيدر
            ZStack {
                Text("الإشعارات").font(.cairo(.bold, size: AppSizes.Font.title2)).foregroundStyle(.white)
                HStack {
                    if notifications.contains(where: { !$0.isRead }) {
                        Button { markAllRead() } label: {
                            Text("قراءة الكل").font(.cairo(.medium, size: AppSizes.Font.caption)).foregroundStyle(AppColors.Default.goldPrimary)
                        }
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(AppSizes.Spacing.lg)

            if isLoading {
                Spacer()
                ProgressView().tint(AppColors.Default.goldPrimary)
                Spacer()
            } else if notifications.isEmpty {
                Spacer()
                VStack(spacing: AppSizes.Spacing.md) {
                    Image(systemName: "bell.slash").font(.system(size: 50)).foregroundStyle(.white.opacity(0.2))
                    Text("لا توجد إشعارات").font(.cairo(.medium, size: AppSizes.Font.body)).foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(notifications) { notif in
                            notificationRow(notif)
                            Divider().overlay(.white.opacity(0.06))
                        }
                    }
                }
            }
        }
        .background(GradientBackground.main)
        .task { await loadNotifications() }
    }

    private func notificationRow(_ notif: AppNotification) -> some View {
        HStack(alignment: .top, spacing: AppSizes.Spacing.sm) {
            // أيقونة حسب النوع
            Image(systemName: notifIcon(notif.type))
                .font(.system(size: 18))
                .foregroundStyle(notifColor(notif.type))
                .frame(width: 36, height: 36)
                .background(notifColor(notif.type).opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(notif.title)
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                Text(notif.body)
                    .font(.cairo(.regular, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            Spacer()

            if !notif.isRead {
                Circle().fill(AppColors.Default.goldPrimary).frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, AppSizes.Spacing.lg)
        .padding(.vertical, AppSizes.Spacing.sm)
        .background(!notif.isRead ? AppColors.Default.goldPrimary.opacity(0.03) : .clear)
    }

    private func notifIcon(_ type: String) -> String {
        switch type {
        case "match_invite": return "gamecontroller.fill"
        case "match_result": return "trophy.fill"
        case "gem_reward": return "diamond.fill"
        case "system": return "bell.fill"
        default: return "envelope.fill"
        }
    }

    private func notifColor(_ type: String) -> Color {
        switch type {
        case "match_invite": return AppColors.Default.info
        case "match_result": return AppColors.Default.goldPrimary
        case "gem_reward": return AppColors.Default.success
        default: return .white.opacity(0.5)
        }
    }

    private func loadNotifications() async {
        isLoading = true; defer { isLoading = false }
        notifications = (try? await network.request(NotificationsEndpoint.List())) ?? []
    }

    private func markAllRead() {
        Task {
            try? await network.requestVoid(NotificationsEndpoint.MarkAllRead())
            await loadNotifications()
            HapticManager.success()
        }
    }
}
