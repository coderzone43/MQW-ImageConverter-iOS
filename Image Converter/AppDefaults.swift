import Foundation

class AppDefaults {
    static let shared = AppDefaults()
    private let defaults = UserDefaults.standard
    private init() {}
    
    var appLanguage: String {
        get { defaults.string(forKey: Constants.appLanguage) ?? "en" }
        set { defaults.setValue(newValue, forKey: Constants.appLanguage) }
    }
    
    var displayMode: String {
        get { defaults.string(forKey: Constants.displayMode) ?? "System" }
        set { defaults.setValue(newValue, forKey: Constants.displayMode) }
    }
    
    var isPremium: Bool {
        get { defaults.bool(forKey: Constants.isPremium) }
        set {
            defaults.setValue(newValue, forKey: Constants.isPremium)
            NotificationCenter.default.post(name:.IAPHelperPurchaseNotification, object: nil)
        }
    }
    
    var freeHitsCount: Int {
        get { defaults.integer(forKey: Constants.freeHitsCount) }
        set { defaults.setValue(newValue, forKey: Constants.freeHitsCount) }
    }
    
    var reviewRequested: Bool {
        get { defaults.bool(forKey: Constants.reviewRequested) }
        set { defaults.setValue(newValue, forKey: Constants.reviewRequested) }
    }
    
    var currentOfferTime: Double {
        get { defaults.double(forKey: Constants.currentOfferTime) }
        set { defaults.setValue(newValue, forKey: Constants.currentOfferTime) }
    }
    
    var canSendQuery: Bool {
        isPremium || freeHitsCount < 2
    }
    
    func incrementFreeHitsCount() {
        if !isPremium {
            freeHitsCount += 1
        }
    }
}
