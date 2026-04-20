//
//  JoinRoomSheet.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Main/Sheets/JoinRoomSheet.swift
//  شاشة الانضمام بكود — 6 خانات أرقام بنمط OTP

import SwiftUI

struct JoinRoomSheet: View {
    let onJoin: (String) -> Void
    @State private var code: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let digits = 6

    var body: some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            Capsule()
                .fill(.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                Text("الانضمام بكود")
                    .font(.cairo(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)
                Text("أدخل كود الغرفة المكوّن من 6 أرقام")
                    .font(.cairo(.regular, size: AppSizes.Font.caption))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // خانات الأرقام
            HStack(spacing: AppSizes.Spacing.sm) {
                ForEach(0..<digits, id: \.self) { i in
                    digitSlot(at: i)
                }
            }
            .environment(\.layoutDirection, .leftToRight) // مهم — الأرقام LTR
            .onTapGesture { isFocused = true }

            // Hidden input field يقود المفاتيح
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.01)
                .frame(height: 0)
                .onChange(of: code) { _, new in
                    // تقليم لـ 6 أرقام فقط + digits
                    let filtered = new.filter { $0.isNumber }
                    if filtered != new { code = filtered }
                    if code.count > digits { code = String(code.prefix(digits)) }
                    // auto-submit عند اكتمال
                    if code.count == digits {
                        submit()
                    }
                }

            if code.count < digits {
                Text("\(digits - code.count) أرقام متبقية")
                    .font(.cairo(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Button {
                submit()
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("انضمام")
                }
                .font(.cairo(.bold, size: AppSizes.Font.body))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSizes.Spacing.sm)
                .background(code.count == digits ? AppColors.Default.goldPrimary : Color.gray.opacity(0.3))
                .clipShape(Capsule())
            }
            .disabled(code.count < digits)
            .padding(.horizontal, AppSizes.Spacing.lg)

            Button("إغلاق") { dismiss() }
                .font(.cairo(.medium, size: AppSizes.Font.body))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, AppSizes.Spacing.md)
        }
        .background(GradientBackground.main)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFocused = true
            }
        }
    }

    // MARK: - خانة رقم واحدة
    private func digitSlot(at index: Int) -> some View {
        let digit: String = {
            if index < code.count {
                let idx = code.index(code.startIndex, offsetBy: index)
                return String(code[idx])
            }
            return ""
        }()
        let isActive = index == code.count

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? AppColors.Default.goldPrimary.opacity(0.1) : Color.white.opacity(0.04))
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? AppColors.Default.goldPrimary : Color.white.opacity(0.15),
                    lineWidth: isActive ? 2 : 1
                )

            Text(digit)
                .font(.poppins(.black, size: 28))
                .foregroundStyle(.white)

            if isActive && digit.isEmpty {
                Rectangle()
                    .fill(AppColors.Default.goldPrimary)
                    .frame(width: 2, height: 28)
                    .opacity(0.8)
            }
        }
        .frame(width: 48, height: 60)
        .animation(.easeInOut(duration: 0.15), value: code)
    }

    private func submit() {
        guard code.count == digits else { return }
        HapticManager.success()
        SoundManager.play(.matchFound)
        onJoin(code)
        dismiss()
    }
}
