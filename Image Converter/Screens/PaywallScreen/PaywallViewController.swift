import UIKit
import Network
import StoreKit
import Localize_Swift

enum PlanType {
    case Weekly
    case Monthly
    case Yearly
    case lifeTime
}

class PaywallViewController: UIViewController {
    
    @IBOutlet weak var cancelButton: UIView!
    @IBOutlet weak var restoreButton: UIView!
    @IBOutlet weak var bannerContainer: UIView!
    @IBOutlet weak var offersCollectionView: UICollectionView!
    @IBOutlet weak var rotatingCollectionView: UICollectionView!
    @IBOutlet weak var privacyButton: UILabel!
    @IBOutlet weak var freePlanButton: UILabel!
    @IBOutlet weak var termsButton: UILabel!
    @IBOutlet weak var freeTrialButton: UIView!
    @IBOutlet weak var freeTrialButtonLabel: UILabel!
    @IBOutlet weak var freeTrialInfoLabel: UILabel!
    @IBOutlet weak var topmostConstraint: NSLayoutConstraint!
    @IBOutlet weak var topmostContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottommostConstraint: NSLayoutConstraint!
    
    var currentOffset: CGFloat = 0
    let hud = ProgressHudUtility()
    var currentSelectedProduct: SKProduct?
    var subscriptionPlanList : [String] = [
        Constants.weeklySubscription,
        Constants.monthlySubscription,
        Constants.yearlySubscription,
        Constants.yearlyOfferSubscription
    ]
    var selectedIndex = 1
    var durationArray = ["Weekly","Monthly","Yearly"]
    var checkedReceiptValidation = false
    var networkManager: NetworkManager?
    
    class func PaywallViewController()-> PaywallViewController{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PaywallViewController") as! PaywallViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Constants.currentDevice.model == "iPad" {
            topmostConstraint.constant = 20
            bottommostConstraint.constant = -20
        } else if Constants.screenSize.height < 812 {
            topmostConstraint.constant = 10
            bottommostConstraint.constant = -10
        }
        
        setupGestures()
        setupCollectionView()
        startInfiniteScroll()
        networkManager = NetworkManager()
        networkManager?.delegate = self
        retriveProducts()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        offersCollectionView.reloadData()
    }
    
    func setupGestures() {
        cancelButton.addTapGestureRecognizer(target: self, action: #selector(cancelButtonTap))
        privacyButton.addTapGestureRecognizer(target: self, action: #selector(privacyButtonTap))
        freePlanButton.addTapGestureRecognizer(target: self, action: #selector(freePlanButtonTap))
        termsButton.addTapGestureRecognizer(target: self, action: #selector(termsButtonTap))
        freeTrialButton.addTapGestureRecognizer(target: self, action: #selector(buyViewTapped))
        restoreButton.addTapGestureRecognizer(target: self, action: #selector(restorePurchase))
    }
    
    func setupCollectionView() {
        offersCollectionView.register(OffersCollectionViewCell.nib(), forCellWithReuseIdentifier: OffersCollectionViewCell.Identifier)
//        offersCollectionView.dataSource = self
//        offersCollectionView.delegate = self
//        offersCollectionView.reloadData()
        
        rotatingCollectionView.register(RotatingCollectionViewCell.nib(), forCellWithReuseIdentifier: RotatingCollectionViewCell.Identifier)
        rotatingCollectionView.dataSource = self
        rotatingCollectionView.delegate = self
        rotatingCollectionView.isUserInteractionEnabled = false
    }
    
    func startInfiniteScroll() {
        currentOffset = rotatingCollectionView.contentOffset.x
        DispatchQueue.main.async { [weak self] in
            self?.continuousScroll()
        }
    }
    
    func continuousScroll() {
        let contentWidth = rotatingCollectionView.contentSize.width
        let collectionViewWidth = rotatingCollectionView.frame.width
        
        if currentOffset >= contentWidth - collectionViewWidth {
            currentOffset = 0
        }
        
        currentOffset += 0.5
        rotatingCollectionView.setContentOffset(CGPoint(x: currentOffset, y: 0), animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.continuousScroll()
        }
    }
}

extension PaywallViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView == offersCollectionView ? subscriptionPlanList.count - 1 : rotatingItems.count * 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == offersCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OffersCollectionViewCell.Identifier, for: indexPath) as? OffersCollectionViewCell else { return UICollectionViewCell() }
            
            
            let item = indexPath.item
            if let product = getProductFromStore(productID: subscriptionPlanList[item]) {
                cell.frequencyLabel.text = durationArray[item].localized()
                cell.priceLabel.text = product.localizedPrice ?? ""
                var plan:PlanType = .Weekly
                if item == 0{
                    plan = .Weekly
                } else if item == 1{
                    plan = .Monthly
                } else if item == 2{
                    plan = .Yearly
                }
                cell.configSelection(isSelected: selectedIndex == indexPath.item)
                guard let baseProduct = getProductFromStore(productID: subscriptionPlanList[0]) else{ return cell}
                let discountInPercentage = getPercentageOffOnPlan(basePrice: Double(truncating: baseProduct.price), discountPrice: Double(truncating: product.price), for: plan)
                
                if item == 0 {
                    let weeklySave = baseProduct.price.doubleValue * 2
                    let text = convertPrice(price: Double(weeklySave), product: product, plan: "/ week".localized(), isLifeTime: true)
                    cell.averageLabel.attributedText = text
                    cell.offerTypeContainer.backgroundColor = UIColor(named: "Tabbar Border")!
                    cell.offerTypeLabel.text = "Basic".localized()
                    cell.offerTypeLabel.textColor = UIColor(named: "Offer Label 2")!
                }
                
                if item == 1{
                    cell.offerTypeContainer.backgroundColor = UIColor(hex: "#8154F5")
                    cell.offerTypeLabel.textColor = UIColor.white
                    cell.offerTypeLabel.text = "Save".localized() + " "  + "\(Int(discountInPercentage))%"
                    cell.averageLabel.attributedText = convertPricePerPlan(price: (Double(truncating: product.price)/4), product: product, plan: "/ week".localized(), isLifeTime: false)
                }
                
                if item == 2{
                    cell.offerTypeLabel.text = "Most Popular".localized()
                    cell.offerTypeLabel.textColor = UIColor.white
                    cell.offerTypeContainer.backgroundColor = UIColor(hex: "#01AF92")
                    cell.averageLabel.attributedText = convertPricePerPlan(price: (Double(truncating: product.price)/52), product: product, plan: "/ week".localized(), isLifeTime: false)
                }
                
                if indexPath.item == selectedIndex {
                    if product.introductoryPrice != nil {
                        freeTrialButtonLabel.text = "Start 3-Days Free Trial".localized()
                        setupUnlimitedFreeAccessLbl(product: product)
                    } else {
                        freeTrialButtonLabel.text = "C O N T I N U E".localized()
                        
                        if indexPath.item == 0{
                            freeTrialInfoLabel.text = "50% off".localized() + ", " + "then".localized() + " " + (product.localizedPrice ?? "") + " " + "per week".localized()
                        } else if indexPath.item == 1 {
                            freeTrialInfoLabel.text = cell.offerTypeLabel.text
                        } else if indexPath.item == 2 {
                            let discountPercentText = "Save".localized() + " " + "\(Int(discountInPercentage))%, "
                            let thenText = "then".localized() + " "
                            let priceText = (product.localizedPrice ?? "") + " "
                            let perYearText = "per year".localized()
                            freeTrialInfoLabel.text = discountPercentText + thenText + priceText + perYearText
                        }
                    }
                }
            }
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RotatingCollectionViewCell.Identifier, for: indexPath) as? RotatingCollectionViewCell else { return UICollectionViewCell() }
            
            cell.configure(with: rotatingItems[indexPath.item % 4])
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == offersCollectionView {
            selectedIndex = indexPath.item
            collectionView.reloadData()
        }
    }
}

extension PaywallViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == offersCollectionView {
            return CGSize(width: collectionView.frame.width, height: (collectionView.frame.height - (Constants.currentDevice.model == "iPad" ? 24 : 16 ))/CGFloat(self.subscriptionPlanList.count - 1))
        } else {
            let rotatingItem = rotatingItems[indexPath.item % 4]
            
            let label = UILabel()
            label.text = rotatingItem.label
            label.font = UIFont.systemFont(ofSize: Constants.currentDevice.model == "iPad" ? 20 : 16)
            
            let maxWidth = collectionView.frame.width
            let size = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
            
            if Constants.currentDevice.model == "iPad" {
                return CGSize(width: size.width + 72, height: 60)
            } else {
                return CGSize(width: size.width + 72, height: 48)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.currentDevice.model == "iPad" ? 12 : 8
    }
}

//MARK: - @objc Methods
extension PaywallViewController {
    @objc func cancelButtonTap() {
        dismiss(animated: true)
    }
    
    @objc func privacyButtonTap() {
        if let url = URL(string: Constants.urlPrivacy) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func freePlanButtonTap() {
        dismiss(animated: true)
    }
    
    @objc func termsButtonTap() {
        if let url = URL(string: Constants.urlTerms) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func buyViewTapped(){
        if !Utility.connected() {
            Utility.showAlert(caller: self, title: Constants.appName.localized(), message: "Please Check Your Internet Connection.".localized())
            return
        }
        hud.showHUD(on: view)
        currentSelectedProduct = self.getProductFromStore(productID: subscriptionPlanList[selectedIndex])
        if let currentSelectedProduct {
            buyPlan(product: currentSelectedProduct)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                hud.hideHUD()
                Utility.showAlert(caller: self, title: Constants.appName.localized(), message: "Something Went Wrong.".localized())
            }
            print("User Cancel Buy.")
        }
    }
    
    @objc func restorePurchase() -> () {
        if !Utility.connected(){
            Utility.noInternetAlert(caller: self)
            return
        }
        self.hud.showHUD(on: self.view)
        SwiftyStoreKit.restorePurchases {[weak self](results) in
            guard let self = self else {return}
            if results.restoredPurchases.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    if let productID = results.restoredPurchases.first?.productId{
                        AppDefaults.shared.isPremium = true
                    }
                    NotificationCenter.default.post(name:.IAPHelperPurchaseNotification, object: nil)
                    Utility.showAlert(caller: self, title: "Success",message: "Successfully Restore.".localized())
                    self.dismiss(animated: true)
                }
            } else if results.restoreFailedPurchases.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    AppDefaults.shared.isPremium = false
                    Utility.showAlert(caller: self, title: "Failed",message: "Restore Failed".localized())
                }
            }else{
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    AppDefaults.shared.isPremium = false
                    Utility.showAlert(caller: self, title: "",message: "Nothing to Restore".localized())
                }
            }
        }
    }
}

//MARK: - Swifty Store Kit Functions
extension PaywallViewController{
    func retriveProducts() -> Void {
        if appDelegate.products.count > 0 && appDelegate.products.count == subscriptionPlanList.count && networkManager?.currentStatus != .disconnected {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                hud.hideHUD()
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                offersCollectionView.delegate = self
                offersCollectionView.dataSource = self
                offersCollectionView.reloadData()
            }
        } else {
            hud.showHUD(on: view)
            SwiftyStoreKit.retrieveProductsInfo(appDelegate.subScriptionsOffers) {[weak self] result in
                guard let self = self else { return }
                let products = result.retrievedProducts
                if products.count > 0 {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        hud.hideHUD()
                        MBProgressHUD.hideAllHUDs(for: view, animated: true)
                        appDelegate.products = products
                        offersCollectionView.delegate = self
                        offersCollectionView.dataSource = self
                        offersCollectionView.reloadData()
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        hud.hideHUD()
                        MBProgressHUD.hideAllHUDs(for: view, animated: true)
                        freeTrialButtonLabel.text = "--"
                        freeTrialInfoLabel.text = "--"
                        offersCollectionView.delegate = nil
                        offersCollectionView.dataSource = nil
                        offersCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func convertPrice(price: Double, product: SKProduct, plan: String, isLifeTime: Bool) -> NSMutableAttributedString {
        let originalPrice = price
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        let tempPrice = numberFormatter.string(from: NSNumber(value: originalPrice)) ?? ""
        var attributeString: NSMutableAttributedString
        
        if isLifeTime {
            attributeString = NSMutableAttributedString(string: "\(tempPrice)\(plan)")
        } else {
            attributeString = NSMutableAttributedString(string: "\(tempPrice)\(plan)")
        }
        attributeString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, attributeString.length))
        if isLifeTime {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length))
        } else {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, 0))
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributeString.length))
        
        return attributeString
    }
    
    func calculateYearlyPrice(fromWeeklyPrice weeklyPrice: Double, product: SKProduct) -> NSMutableAttributedString {
        let yearlyPrice = weeklyPrice * 52
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        let formattedYearlyPrice = numberFormatter.string(from: NSNumber(value: yearlyPrice)) ?? ""
        let attributeString = NSMutableAttributedString(string: "\(formattedYearlyPrice)/Year")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributeString.length))
        return attributeString
    }
    
    func getProductFromStore(productID:String) ->SKProduct?{
        if appDelegate.products.count > 0{
            let product = appDelegate.products.first { product in
                return product.productIdentifier == productID
            }
            return product
        }else{
            return nil
        }
    }
    
    func convertPricePerPlan(price:Double,product:SKProduct,plan:String,isLifeTime:Bool) -> NSMutableAttributedString {
        let orignalPrice = price
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        let tempPrice = numberFormatter.string(from: NSNumber(value: orignalPrice)) ?? ""
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: String("\(tempPrice)\(plan)"))
        if isLifeTime{
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0,attributeString.length))
        }else{
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0,0))
        }
        return attributeString
    }
    
    func getPercentageOffOnPlan(basePrice : Double, discountPrice: Double, for duration: PlanType ) -> Int {
        if duration == .Yearly {
            let discount = Int(100 - (discountPrice) / (basePrice * 52) * 100)
            return discount
        }
        if duration == .Monthly {
            let discount = Int(100 - (discountPrice) / (basePrice * 4) * 100)
            return discount
        }
        return 0
    }
    
    func setupUnlimitedFreeAccessLbl(product: SKProduct) {
        let textColor = UIColor.label
        var subscriptionType = ""
        switch product.productIdentifier {
        case Constants.weeklySubscription:
            subscriptionType = "week".localized()
        case Constants.monthlySubscription:
            subscriptionType = "month".localized()
        case Constants.yearlySubscription:
            subscriptionType = "year".localized()
        default:
            break
        }
        
        guard let numberOfFreeTrailDays = product.introductoryPrice?.subscriptionPeriod.numberOfUnits else{return}
        let priceString = product.localizedPrice ?? "$0.00"
        let subscriptionPeriod = "per".localized() + " \(subscriptionType)"
        let firstString = NSMutableAttributedString(string: "Try Free For".localized() + " \(numberOfFreeTrailDays) " + "Days".localized() + ", ", attributes: [.foregroundColor: textColor])
        let secondString = NSAttributedString(string: "then".localized() + " \(priceString) \(subscriptionPeriod)", attributes: [.foregroundColor: textColor])
        
        firstString.append(secondString)
        freeTrialInfoLabel.attributedText = firstString
    }
    
    func buyPlan(product: SKProduct){
        SwiftyStoreKit.purchaseProduct(product.productIdentifier, quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                AppDefaults.shared.isPremium = true
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    NotificationCenter.default.post(name:.IAPHelperPurchaseNotification, object: nil)
                    self.dismiss(animated: true)
                }
            case .error(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    Utility.showAlert(caller: self, title: "Error".localized(), message: "Could not complete the process".localized())
                }
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                default: print((error as NSError).localizedDescription)
                }
            case .restored(purchase: let purchase):
                DispatchQueue.main.async {[weak self] in
                    guard let self else{return}
                    self.hud.hideHUD()
                    AppDefaults.shared.isPremium = true
                    Utility.showAlert(caller: self, title: "Success".localized(),message: "You have purchased Successfully".localized())
                    NotificationCenter.default.post(name:.IAPHelperPurchaseNotification, object: nil)
                    self.dismiss(animated: true)
                }
                
                break
            }
        }
    }
}

// MARK: - NetworkManagerDelegate
extension PaywallViewController: NetworkManagerDelegate {
    func networkStatusChanged(status: NetworkStatus) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .connected, .wifi, .ethernet, .mobileData, .slowConnection:
                self?.retriveProducts()
            case .disconnected:
                self?.freeTrialButtonLabel.text = "--"
                self?.freeTrialInfoLabel.text = "--"
                self?.offersCollectionView.delegate = nil
                self?.offersCollectionView.dataSource = nil
                self?.offersCollectionView.reloadData()
            }
        }
    }
}
