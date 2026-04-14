//
//  IAPManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/IAPManager.swift
//  إدارة المشتريات داخل التطبيق — StoreKit 2

import Foundation
import StoreKit
import Combine

// MARK: - باقات الجواهر
enum GemPackage: String, CaseIterable, Identifiable {
    case tiny   = "com.saifiq.gems.50"
    case small  = "com.saifiq.gems.300"
    case medium = "com.saifiq.gems.700"
    case large  = "com.saifiq.gems.1500"
    case king   = "com.saifiq.gems.5000"

    var id: String { rawValue }

    var gems: Int {
        switch self {
        case .tiny: return 50; case .small: return 300
        case .medium: return 700; case .large: return 1500; case .king: return 5000
        }
    }

    var bonusGold: Int {
        switch self {
        case .large: return 200; case .king: return 1000; default: return 0
        }
    }

    var nameAr: String {
        switch self {
        case .tiny: return "حفنة جواهر"; case .small: return "كيس جواهر"
        case .medium: return "صندوق جواهر"; case .large: return "خزنة جواهر"; case .king: return "باقة الملك 👑"
        }
    }

    var icon: String {
        switch self {
        case .tiny: return "diamond"; case .small: return "diamond.fill"
        case .medium: return "gift.fill"; case .large: return "safe.fill"; case .king: return "crown.fill"
        }
    }

    var isBestValue: Bool { self == .medium }
    var isPopular: Bool { self == .small }
}

// MARK: - IAP Manager
@MainActor
final class IAPManager: ObservableObject {

    static let shared = IAPManager()

    // MARK: - State
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    @Published var isPurchasing = false

    // MARK: - Dependencies
    private let network: NetworkClient = NetworkManager.shared
    private let toast = ToastManager.shared
    private var updateTask: Task<Void, Never>?

    // MARK: - Init
    private init() {
        updateTask = listenForTransactions()
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - ═══════ تحميل المنتجات ═══════

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let ids = Set(GemPackage.allCases.map(\.rawValue))
            products = try await Product.products(for: ids)
                .sorted { ($0.price as NSDecimalNumber).doubleValue < ($1.price as NSDecimalNumber).doubleValue }
            #if DEBUG
            print("✅ [IAP] Loaded \(products.count) products")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [IAP] Failed to load products: \(error)")
            #endif
        }
    }

    // MARK: - ═══════ الشراء ═══════

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // إرسال للباك اند للتحقق
                let verified = await verifyOnServer(
                    productId: product.id,
                    transactionId: String(transaction.id)
                )

                if verified {
                    await transaction.finish()
                    HapticManager.success()

                    let pkg = GemPackage(rawValue: product.id)
                    toast.success("تم الشراء! +\(pkg?.gems ?? 0) 💎")

                    // تحديث بيانات المستخدم
                    _ = try? await AuthService.shared.getMe()
                    return true
                } else {
                    toast.error("فشل التحقق من الشراء")
                    return false
                }

            case .userCancelled:
                return false

            case .pending:
                toast.info("الشراء قيد المعالجة...")
                return false

            @unknown default:
                return false
            }
        } catch {
            toast.error("فشل الشراء: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - ═══════ استعادة المشتريات ═══════

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            toast.success("تمت استعادة المشتريات")
        } catch {
            toast.error("فشلت الاستعادة")
        }
    }

    // MARK: - ═══════ Private ═══════

    /// التحقق من التوقيع
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let safe): return safe
        }
    }

    /// إرسال للباك اند للتحقق
    private func verifyOnServer(productId: String, transactionId: String) async -> Bool {
        do {
            let endpoint = IAPEndpoint.Verify(
                productId: productId,
                transactionId: transactionId
            )
            _ = try await network.request(endpoint)
            return true
        } catch {
            #if DEBUG
            print("⚠️ [IAP] Server verification failed: \(error)")
            #endif
            return false
        }
    }

    /// مراقبة المعاملات (للمشتريات المعلقة)
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }

    /// الحصول على سعر المنتج
    func priceFor(_ package: GemPackage) -> String {
        products.first { $0.id == package.rawValue }?.displayPrice ?? "..."
    }
}
