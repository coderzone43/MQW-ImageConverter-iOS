import Foundation
import UIKit

let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate

class Constants {
    static let appLanguage = "AppLanguage"
    static let displayMode = "DisplayMode"
    static let freeHitsCount = "freeHitsCount"
    static let isPremium = "isPremium"
    static let reviewRequested = "reviewRequested"
    static let currentOfferTime = "currentOfferTime"
    
    static let appName = "Image Converter"
    static let SharedSecret = "94c393942d104ecf807d9ca14104bd8b"
    static let appID = "6751902822"
    
    static let weeklySubscription = "com.mqw.image.converter.weekly"
    static let monthlySubscription = "com.mqw.image.converter.monthly"
    static let yearlySubscription = "com.mqw.image.converter.yearly"
    static let yearlyOfferSubscription = "com.mqw.image.converter.yearly.offer"
    
    static let urlTerms = "https://sites.google.com/view/muhammadqasimwali/terms-of-use"
    static let urlPrivacy = "https://sites.google.com/view/muhammadqasimwali/privacy-policy"
    static let urlSupport = "https://sites.google.com/view/muhammadqasimwali/customer-support"
    static let urlAppStore = "https://apps.apple.com/us/app/id\(appID)"
    static let urlRate = "https://apps.apple.com/app/id\(appID)?action=write-review"
    static let urlMoreApps = "https://apps.apple.com/developer/muhammad-qasim-wali/id1772758953"
    static let supportEmail = "mailto:muhammadqasimwali45@gmail.com"
    
    static let screenSize: CGRect = UIScreen.main.bounds
    static let currentDevice = UIDevice.current
}

extension Notification.Name {
    static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}

func isIOS26() -> Bool {
    guard #available(iOS 26.0, *) else { return false }
    return true
}

struct ScreenSize{
  static let SCREEN_WIDTH     = UIScreen.main.bounds.size.width
  static let SCREEN_HEIGHT    = UIScreen.main.bounds.size.height
  static let SCREEN_MAX_LENGTH  = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
  static let SCREEN_MIN_LENGTH  = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType {
  static let isIpad       = UIDevice.current.userInterfaceIdiom == .pad
  static let isIphone       = UIDevice.current.userInterfaceIdiom == .phone
}
