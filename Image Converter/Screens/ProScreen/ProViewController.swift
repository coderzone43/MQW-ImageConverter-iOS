import UIKit
import Network
import StoreKit

class ProViewController: UIViewController {
    
    @IBOutlet weak var cancelButton: UIView!
    @IBOutlet weak var restoreButton: UIView!
    @IBOutlet weak var rotatingCollectionView: UICollectionView!
    @IBOutlet weak var startTrialButton: UIView!
    @IBOutlet weak var privacyButton: UILabel!
    @IBOutlet weak var freePlanButton: UILabel!
    @IBOutlet weak var freePlanButtonLabel: UILabel!
    @IBOutlet weak var termsButton: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var offerLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topmostConstraint: NSLayoutConstraint!
    @IBOutlet weak var topmostContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottommostConstraint: NSLayoutConstraint!
    
    var currentOffset: CGFloat = 0
    private var timerManager: TimerManager?
    let hud = ProgressHudUtility()
    var currentSelectedProduct: SKProduct?
    var subscriptionPlanList: [String] = [Constants.yearlyOfferSubscription]
    var checkedReceiptValidation = false
    var networkManager: NetworkManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Constants.currentDevice.model == "iPad" {
            topmostConstraint.constant = 20
            bottommostConstraint.constant = -20
        } else if Constants.screenSize.height < 812 {
            topmostConstraint.constant = 10
            topmostContainerHeightConstraint.constant = 350
            bottommostConstraint.constant = -10
        }
        
        setUpTimer()
        setupGestures()
        setupCollectionView()
        startInfiniteScroll()
        networkManager = NetworkManager()
        networkManager?.delegate = self
        retriveProducts()
    }
    
    private func setupGestures() {
        cancelButton.addTapGestureRecognizer(target: self, action: #selector(cancelButtonTap))
        privacyButton.addTapGestureRecognizer(target: self, action: #selector(privacyButtonTap))
        freePlanButton.addTapGestureRecognizer(target: self, action: #selector(freePlanButtonTap))
        termsButton.addTapGestureRecognizer(target: self, action: #selector(termsButtonTap))
        restoreButton.addTapGestureRecognizer(target: self, action: #selector(restorePurchase))
        startTrialButton.addTapGestureRecognizer(target: self, action: #selector(buyViewTapped))
    }
    
    private func setupCollectionView() {
        rotatingCollectionView.register(RotatingCollectionViewCell.nib(), forCellWithReuseIdentifier: RotatingCollectionViewCell.Identifier)
        rotatingCollectionView.dataSource = self
        rotatingCollectionView.delegate = self
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        rotatingCollectionView.collectionViewLayout = layout
        rotatingCollectionView.isUserInteractionEnabled = false
    }
    
    private func startInfiniteScroll() {
        currentOffset = rotatingCollectionView.contentOffset.x
        DispatchQueue.main.async {
            self.continuousScroll()
        }
    }
    
    private func continuousScroll() {
        let contentWidth = rotatingCollectionView.contentSize.width
        let collectionViewWidth = rotatingCollectionView.frame.width
        
        if currentOffset >= contentWidth - collectionViewWidth {
            currentOffset = 0
        }
        
        currentOffset += 0.5
        rotatingCollectionView.setContentOffset(CGPoint(x: self.currentOffset, y: 0), animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.continuousScroll()
        }
    }
    
    func setupYearlyPlanView() {
        if let prod = self.getProductFromStore(productID: subscriptionPlanList[0]) {
            let localizedPrice = prod.localizedPrice ?? ""
            var localizedIntroPrice = ""
            if let discount = prod.introductoryPrice {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = discount.priceLocale
                localizedIntroPrice = formatter.string(from: discount.price) ?? ""
            }
            
            offerLabel.text = "Only".localized() + " " + localizedIntroPrice + " " + "for 1 year, then".localized() + " " + localizedPrice + " " + "per year".localized()
            amountLabel.attributedText = priceWithOff(
                originalPrice: Double(truncating: prod.introductoryPrice?.price ?? 0) / 365,
                product: prod,
                line: false
            )
        }
    }
    
    func priceWithOff(originalPrice: Double, product: SKProduct, line: Bool) -> NSAttributedString {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        let tempPrice = numberFormatter.string(from: NSNumber(value: originalPrice)) ?? ""
        let attributeString = NSMutableAttributedString(string: String("\(tempPrice)"))
        if line {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length))
        } else {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, 0))
        }
        return attributeString
    }
    
    func setUpTimer() {
        timerLabel.text = "--"
        if !containerView.isHidden {
            timerManager = TimerManager()
            timerManager?.startTimer { [weak self] timeString in
                guard let self else { return }
                self.timerLabel.text = timeString
            }
        }
    }
}

extension ProViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rotatingItems.count * 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RotatingCollectionViewCell.Identifier, for: indexPath) as? RotatingCollectionViewCell else { return UICollectionViewCell() }
        
        cell.configure(with: rotatingItems[indexPath.item % 4])
        return cell
    }
}

extension ProViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
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

extension ProViewController {
    func retriveProducts() {
        if appDelegate.products.count > 0 && appDelegate.products.count - 3 == subscriptionPlanList.count && networkManager?.currentStatus != .disconnected {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                hud.hideHUD()
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                containerView.isHidden = false
                setupYearlyPlanView()
            }
        } else {
            hud.showHUD(on: view)
            SwiftyStoreKit.retrieveProductsInfo(appDelegate.subScriptionsOffers) { [weak self] result in
                guard let self = self else { return }
                let products = result.retrievedProducts
                if products.count > 0 {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        hud.hideHUD()
                        MBProgressHUD.hideAllHUDs(for: view, animated: true)
                        appDelegate.products = products
                        containerView.isHidden = false
                        setupYearlyPlanView()
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        hud.hideHUD()
                        MBProgressHUD.hideAllHUDs(for: view, animated: true)
                        freePlanButtonLabel.text = "--"
                        containerView.isHidden = true
                    }
                }
            }
        }
    }
    
    func getProductFromStore(productID: String) -> SKProduct? {
        if appDelegate.products.count > 0 {
            let product = appDelegate.products.first { product in
                return product.productIdentifier == productID
            }
            return product
        } else {
            return nil
        }
    }
    
    func buyPlan(product: SKProduct) {
        SwiftyStoreKit.purchaseProduct(product.productIdentifier, quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                AppDefaults.shared.isPremium = true
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: nil)
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
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    AppDefaults.shared.isPremium = true
                    Utility.showAlert(caller: self, title: "Success".localized(), message: "You have purchased Successfully".localized())
                    NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: nil)
                    self.dismiss(animated: true)
                }
            }
        }
    }
}

// MARK: - NetworkManagerDelegate
extension ProViewController: NetworkManagerDelegate {
    func networkStatusChanged(status: NetworkStatus) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .connected, .wifi, .ethernet, .mobileData, .slowConnection:
                self?.retriveProducts()
            case .disconnected:
                self?.freePlanButtonLabel.text = "--"
                self?.containerView.isHidden = true
            }
        }
    }
}


// MARK: - @objc Methods
extension ProViewController {
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
    
    @objc func buyViewTapped() {
        if !Utility.connected() {
            Utility.showAlert(caller: self, title: Constants.appName.localized(), message: "Please Check Your Internet Connection.".localized())
            return
        }
        hud.showHUD(on: view)
        currentSelectedProduct = self.getProductFromStore(productID: subscriptionPlanList[0])
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
    
    @objc func restorePurchase() {
        if !Utility.connected() {
            Utility.noInternetAlert(caller: self)
            return
        }
        self.hud.showHUD(on: self.view)
        SwiftyStoreKit.restorePurchases { [weak self] results in
            guard let self = self else { return }
            if results.restoredPurchases.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    if let productID = results.restoredPurchases.first?.productId {
                        AppDefaults.shared.isPremium = true
                    }
                    NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: nil)
                    Utility.showAlert(caller: self, title: "Success", message: "Successfully Restore.".localized())
                    self.dismiss(animated: true)
                }
            } else if results.restoreFailedPurchases.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    AppDefaults.shared.isPremium = false
                    Utility.showAlert(caller: self, title: "Failed", message: "Restore Failed".localized())
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.hud.hideHUD()
                    AppDefaults.shared.isPremium = false
                    Utility.showAlert(caller: self, title: "", message: "Nothing to Restore".localized())
                }
            }
        }
    }
}
