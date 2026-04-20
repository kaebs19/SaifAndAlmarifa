//
//  QRCodeView.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Components/QRCodeView.swift
//  مكوّن QR Code من أي نص — CoreImage

import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeView: View {
    let string: String
    var size: CGFloat = 200
    var tintColor: UIColor = .black
    var backgroundColor: UIColor = .white

    var body: some View {
        Group {
            if let image = generateImage() {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .background(Color(backgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay(Text("QR تعذّر").font(.cairo(.medium, size: 11)))
            }
        }
    }

    private func generateImage() -> UIImage? {
        guard !string.isEmpty else { return nil }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // أعلى مقاومة للأخطاء

        guard let output = filter.outputImage else { return nil }

        // كبّر الصورة (بدون blur بسبب .interpolation(.none))
        let scale: CGFloat = 12
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // تلوين
        let colored = transformed.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(color: tintColor),
            "inputColor1": CIColor(color: backgroundColor)
        ])

        guard let cgImage = context.createCGImage(colored, from: colored.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - شاشة QR منفصلة (sheet)
struct RoomQRSheet: View {
    let code: String
    let shareLink: String?
    let modeName: String
    @Environment(\.dismiss) private var dismiss

    private var qrString: String {
        shareLink ?? "saifiq://join/\(code)"
    }

    var body: some View {
        VStack(spacing: AppSizes.Spacing.lg) {
            Capsule()
                .fill(.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text("امسح للانضمام")
                    .font(.cairo(.bold, size: AppSizes.Font.title2))
                    .foregroundStyle(.white)
                Text(modeName)
                    .font(.cairo(.medium, size: AppSizes.Font.caption))
                    .foregroundStyle(AppColors.Default.goldPrimary)
            }

            // QR كبير
            QRCodeView(
                string: qrString,
                size: 260,
                tintColor: UIColor(Color(hex: "0A0E27")),
                backgroundColor: .white
            )
            .padding(AppSizes.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFE55C"), Color(hex: "FFD700")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.Default.goldPrimary.opacity(0.4), radius: 20)

            // الكود كنص احتياطي
            VStack(spacing: 4) {
                Text("أو استخدم الكود")
                    .font(.cairo(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                Text(code)
                    .font(.poppins(.black, size: 28))
                    .foregroundStyle(AppColors.Default.goldPrimary)
                    .tracking(6)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("إغلاق")
                    .font(.cairo(.bold, size: AppSizes.Font.body))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSizes.Spacing.sm)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppSizes.Spacing.lg)
            .padding(.bottom, AppSizes.Spacing.md)
        }
        .background(GradientBackground.main)
    }
}
