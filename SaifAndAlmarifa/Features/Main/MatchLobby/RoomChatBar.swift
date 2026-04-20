//
//  RoomChatBar.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Main/MatchLobby/RoomChatBar.swift
//  شات مصغّر في لوبي الغرفة — يعرض آخر الرسائل + إرسال سريع

import SwiftUI

struct RoomChatBar: View {
    @ObservedObject var viewModel: MainViewModel

    @State private var expanded = false
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // زر الفتح/الإغلاق
            Button {
                HapticManager.light()
                withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() }
                if expanded {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFocused = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(AppColors.Default.goldPrimary)
                    Text("شات الغرفة")
                        .font(.cairo(.bold, size: AppSizes.Font.caption))
                        .foregroundStyle(.white)
                    if !viewModel.roomMessages.isEmpty {
                        Text("\(viewModel.roomMessages.count)")
                            .font(.poppins(.bold, size: 10))
                            .foregroundStyle(.black)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(AppColors.Default.goldPrimary)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, AppSizes.Spacing.md)
                .padding(.vertical, 10)
                .background(.white.opacity(0.05))
            }

            if expanded {
                messagesList
                inputBar
            }
        }
    }

    // MARK: - قائمة الرسائل
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    if viewModel.roomMessages.isEmpty {
                        Text("ابدأ المحادثة...")
                            .font(.cairo(.regular, size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.roomMessages) { msg in
                            messageRow(msg)
                                .id(msg.id)
                        }
                    }
                }
                .padding(.horizontal, AppSizes.Spacing.md)
                .padding(.top, AppSizes.Spacing.sm)
            }
            .frame(height: 180)
            .background(Color.black.opacity(0.15))
            .onChange(of: viewModel.roomMessages.count) { _, _ in
                if let last = viewModel.roomMessages.last?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }

    private func messageRow(_ msg: RoomChatMessage) -> some View {
        let isMine = msg.userId == viewModel.user?.id
        return HStack(alignment: .bottom, spacing: 6) {
            if isMine { Spacer(minLength: 40) }
            if !isMine {
                AvatarView(imageURL: msg.avatarUrl, size: 20)
            }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 1) {
                if !isMine {
                    Text(msg.username)
                        .font(.cairo(.semiBold, size: 9))
                        .foregroundStyle(AppColors.Default.goldPrimary)
                }
                Text(msg.content)
                    .font(.cairo(.regular, size: 12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(isMine ? Color(hex: "6366F1").opacity(0.35) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if !isMine { Spacer(minLength: 40) }
        }
    }

    // MARK: - Input
    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("اكتب رسالة...", text: $text)
                .font(.cairo(.regular, size: 12))
                .foregroundStyle(.white)
                .tint(AppColors.Default.goldPrimary)
                .padding(.horizontal, AppSizes.Spacing.sm)
                .padding(.vertical, 6)
                .background(.white.opacity(0.06))
                .clipShape(Capsule())
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit { send() }

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 34, height: 34)
                    .background(text.isEmpty ? Color.gray.opacity(0.3) : AppColors.Default.goldPrimary)
                    .clipShape(Circle())
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, AppSizes.Spacing.md)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
    }

    private func send() {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        viewModel.sendRoomMessage(t)
        text = ""
        HapticManager.light()
    }
}
