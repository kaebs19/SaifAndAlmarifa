//
//  AdManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 13/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/AdManager.swift
//  مدير إعلانات Google AdMob — إعلانات مكافأة + بينية

import Foundation
import UIKit
import Combine
import GoogleMobileAds

// MARK: - Ad Config
enum AdConfig {
    #if DEBUG
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    static let rewardedAdUnitID = "ca-app-pub-XXXX/YYYY"
    static let interstitialAdUnitID = "ca-app-pub-XXXX/ZZZZ"
    #endif
}

// MARK: - Ad Manager
@MainActor
final class AdManager: NSObject, ObservableObject {

    static let shared = AdManager()

    @Published var isRewardedAdReady = false
    @Published var isInterstitialReady = false
    @Published private(set) var isShowingAd = false

    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?
    private var rewardCompletion: ((Bool) -> Void)?

    private override init() { super.init() }

    // MARK: - تهيئة
    static func configure() {
        MobileAds.shared.start { _ in
            #if DEBUG
            print("✅ [AdMob] Initialized")
            #endif
        }
        Task { @MainActor in
            await shared.loadRewardedAd()
            await shared.loadInterstitialAd()
        }
    }

    // MARK: - ═══════════════ Rewarded ═══════════════

    func loadRewardedAd() async {
        do {
            rewardedAd = try await RewardedAd.load(with: AdConfig.rewardedAdUnitID, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
            isRewardedAdReady = true
        } catch {
            isRewardedAdReady = false
            #if DEBUG
            print("⚠️ [AdMob] Rewarded load failed: \(error.localizedDescription)")
            #endif
        }
    }

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, let rootVC = Self.topVC() else {
            completion(false)
            return
        }
        isShowingAd = true
        rewardCompletion = completion
        ad.present(from: rootVC) { [weak self] in
            self?.rewardCompletion?(true)
            self?.rewardCompletion = nil
        }
    }

    // MARK: - ═══════════════ Interstitial ═══════════════

    func loadInterstitialAd() async {
        do {
            interstitialAd = try await InterstitialAd.load(with: AdConfig.interstitialAdUnitID, request: Request())
            interstitialAd?.fullScreenContentDelegate = self
            isInterstitialReady = true
        } catch {
            isInterstitialReady = false
        }
    }

    func showInterstitialAd() {
        guard let ad = interstitialAd, let rootVC = Self.topVC() else { return }
        isShowingAd = true
        ad.present(from: rootVC)
    }

    // MARK: - Helper
    private static func topVC() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

// MARK: - Delegate
extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            isShowingAd = false
            if ad is RewardedAd {
                isRewardedAdReady = false
                await loadRewardedAd()
            } else if ad is InterstitialAd {
                isInterstitialReady = false
                await loadInterstitialAd()
            }
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            isShowingAd = false
            rewardCompletion?(false)
            rewardCompletion = nil
        }
    }
}
