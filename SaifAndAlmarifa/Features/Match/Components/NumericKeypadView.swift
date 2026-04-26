//
//  NumericKeypadView.swift
//  SaifAndAlmarifa
//
//  Path: SaifAndAlmarifa/Features/Match/Components/NumericKeypadView.swift
//  لوحة مفاتيح رقمية مخصّصة — احترافية
//

import SwiftUI

struct NumericKeypadView: View {
    @Binding var value: String
    let isDisabled: Bool
    let canSubmit: Bool
    let onSubmit: () -> Void

    private let maxLength: Int = 12

    var body: some View {
        VStack(spacing: 10) {
            row(["1", "2", "3"])
            row(["4", "5", "6"])
            row(["7", "8", "9"])
            HStack(spacing: 10) {
                deleteKey
                digitKey("0")
                submitKey
            }
        }
        .opacity(isDisabled ? 0.5 : 1)
        .allowsHitTesting(!isDisabled)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
    }

    // MARK: - Rows
    private func row(_ digits: [String]) -> some View {
        HStack(spacing: 10) {
            ForEach(digits, id: \.self) { d in
                digitKey(d)
            }
        }
    }

    // MARK: - Digit
    private func digitKey(_ digit: String) -> some View {
        KeypadButton(
            kind: .digit,
            label: digit,
            action: { tapDigit(digit) }
        )
    }

    // MARK: - Delete
    private var deleteKey: some View {
        KeypadButton(
            kind: .delete,
            label: "⌫",
            action: tapDelete,
            longPressAction: { value = "" }   // ضغطة طويلة = مسح الكل
        )
    }

    // MARK: - Submit
    private var submitKey: some View {
        KeypadButton(
            kind: canSubmit ? .submit : .submitDisabled,
            label: "✓",
            action: { if canSubmit { onSubmit() } }
        )
    }

    // MARK: - Actions
    private func tapDigit(_ d: String) {
        guard value.count < maxLength else {
            HapticManager.warning()
            return
        }
        value += d
        HapticManager.light()
    }

    private func tapDelete() {
        guard !value.isEmpty else { return }
        value.removeLast()
        HapticManager.light()
    }
}

// MARK: - Keypad Button
private struct KeypadButton: View {
    enum Kind {
        case digit
        case delete
        case submit
        case submitDisabled
    }

    let kind: Kind
    let label: String
    let action: () -> Void
    var longPressAction: (() -> Void)? = nil

    @State private var isPressed: Bool = false

    private var fillColors: [Color] {
        switch kind {
        case .digit:
            return [Color.white.opacity(0.14), Color.white.opacity(0.06)]
        case .delete:
            return [Color(hex: "F87171").opacity(0.18), Color(hex: "F87171").opacity(0.08)]
        case .submit:
            return [Color(hex: "FFE55C"), Color(hex: "FFB800")]
        case .submitDisabled:
            return [Color.white.opacity(0.06), Color.white.opacity(0.03)]
        }
    }

    private var borderColor: Color {
        switch kind {
        case .digit:           return .white.opacity(0.18)
        case .delete:          return Color(hex: "F87171").opacity(0.45)
        case .submit:          return Color(hex: "FFE55C").opacity(0.7)
        case .submitDisabled:  return .white.opacity(0.10)
        }
    }

    private var labelColor: Color {
        switch kind {
        case .digit:           return .white
        case .delete:          return Color(hex: "FCA5A5")
        case .submit:          return .black
        case .submitDisabled:  return .white.opacity(0.3)
        }
    }

    private var glowColor: Color {
        switch kind {
        case .submit:  return Color(hex: "FFD700").opacity(0.6)
        case .delete:  return Color(hex: "F87171").opacity(0.4)
        default:       return .clear
        }
    }

    private var fontStyle: Font {
        switch kind {
        case .digit:
            return .poppins(.black, size: 28)
        case .delete, .submit, .submitDisabled:
            return .system(size: 24, weight: .black)
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: fillColors,
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.2)

                // ضوء داخلي خفيف فوق
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .clear],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.overlay)

                Text(label)
                    .font(fontStyle)
                    .monospacedDigit()
                    .foregroundStyle(labelColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .shadow(color: glowColor, radius: isPressed ? 4 : 10)
            .scaleEffect(isPressed ? 0.94 : 1.0)
        }
        .buttonStyle(PressableStyle(isPressed: $isPressed))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if let lp = longPressAction {
                        HapticManager.heavy()
                        lp()
                    }
                }
        )
    }
}

// MARK: - Pressable Style (يضبط isPressed)
private struct PressableStyle: ButtonStyle {
    @Binding var isPressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newVal in
                withAnimation(.easeOut(duration: 0.12)) { isPressed = newVal }
            }
    }
}

// MARK: - Preview
private struct KeypadPreviewWrapper: View {
    @State var v: String = "1976"
    var body: some View {
        ZStack {
            Color(hex: "08091E").ignoresSafeArea()
            VStack {
                Text(v.isEmpty ? "—" : v)
                    .font(.poppins(.black, size: 48))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding()
                NumericKeypadView(
                    value: $v, isDisabled: false,
                    canSubmit: !v.isEmpty, onSubmit: {}
                )
                .padding()
            }
        }
    }
}

#Preview {
    KeypadPreviewWrapper()
}
