//
//  OrientationManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 10/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/OrientationManager.swift
//  التحكم في اتجاه الشاشة (عمودي / عرضي)

import SwiftUI
import UIKit

// MARK: - Orientation Manager
class OrientationManager {
    static let shared = OrientationManager()
    private init() {}

    /// القفل الحالي
    var locked: UIInterfaceOrientationMask = .all

    /// قفل على وضع عرضي
    func lockLandscape() {
        locked = .landscape
        rotateToLandscape()
    }

    /// قفل على وضع عمودي
    func lockPortrait() {
        locked = .portrait
        rotateToPortrait()
    }

    /// فك القفل
    func unlock() {
        locked = .all
    }

    private func rotateToLandscape() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
        scene.requestGeometryUpdate(geometryPreferences)
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func rotateToPortrait() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        scene.requestGeometryUpdate(geometryPreferences)
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

// MARK: - ViewModifier لتطبيق الاتجاه
struct LandscapeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear { OrientationManager.shared.lockLandscape() }
            .onDisappear { OrientationManager.shared.lockPortrait() }
    }
}

extension View {
    func forceLandscape() -> some View {
        self.modifier(LandscapeModifier())
    }
}
