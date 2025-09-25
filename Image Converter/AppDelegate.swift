//
//  AppDelegate.swift
//  Image Converter
//
//  Created by Macbook Pro on 29/08/2025.
//

import UIKit
import StoreKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var products: Set<SKProduct> = []
    var subScriptionsOffers: Set<String> = [
        Constants.weeklySubscription,
        Constants.monthlySubscription,
        Constants.yearlySubscription,
        Constants.yearlyOfferSubscription
    ]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initialConfiguration()
        setUpRetrieveProducts()
        getPurchases()
        checkStatusOfPremiumUser()
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) { }
}

// MARK: - Initial Setup and Language Configuration
extension AppDelegate {
    
    // MARK: - Initial Configuration
    fileprivate func initialConfiguration() {
        if !(AppDefaults.shared.freeHitsCount > 0) {
            AppDefaults.shared.freeHitsCount = 1
        }
    }
    
}
// MARK: - Payment and Subscription Handling
extension AppDelegate {
    
    // MARK: - Check Premium User Status
    @objc func checkStatusOfPremiumUser() {
        if Utility.connected() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.verifyReceipt { isPro in
                    if isPro {
                        NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Retrieve User Purchases
    func getPurchases() {
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
            return true // Allow all store payments
        }
        
        // Complete any pending transactions
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction) // Finalize the transaction if needed
                    }
                    // Unlock the content for the user here
                case .failed, .purchasing, .deferred:
                    break // Do nothing for failed or pending transactions
                @unknown default:
                    break
                }
            }
        }
    }
    
    func setUpRetrieveProducts() {
        SwiftyStoreKit.retrieveProductsInfo(subScriptionsOffers) { [weak self] (results) in
            guard let self = self else { return }
            if results.retrievedProducts.count > 0 {
                self.products = results.retrievedProducts
            }
        }
    }
}

// MARK: - Receipt Verification and Premium Status Management
extension AppDelegate {
    
    // MARK: - Verify In-App Purchase Receipt
    func verifyReceipt(_ completion: @escaping (_ isPro: Bool) -> Void) {
        let productIdentifiers = subScriptionsOffers // Get product identifiers for subscriptions
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: Constants.SharedSecret)

        // Verify the receipt using the validator
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                // Check the status of auto-renewable subscriptions in the receipt
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(ofType: .autoRenewable, productIds: productIdentifiers, inReceipt: receipt, validUntil: Date())
                switch purchaseResult {
                case .purchased(_, _):
                    AppDefaults.shared.isPremium = true
                    completion(true)
                case .expired(_, _):
                    AppDefaults.shared.isPremium = false
                    completion(false)
                case .notPurchased:
                    AppDefaults.shared.isPremium = false
                    completion(false)
                case .billingRetry(expiryDate: _, items: _):
                    completion(AppDefaults.shared.isPremium)
                }
            case .error(error: _):
                AppDefaults.shared.isPremium = false
                completion(false)
            case .cancelError(error: _):
                AppDefaults.shared.isPremium = false
                completion(false)
            }
        }
    }
}
