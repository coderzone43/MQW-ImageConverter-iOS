import UIKit

class SettingsViewController: BaseVC {

    @IBOutlet weak var customNavbar: CustomNavbar!
    @IBOutlet weak var settingsCollectionView: UICollectionView!
    @IBOutlet weak var proView: UIView!
    @IBOutlet weak var tryNowButton: UIView!
    
    let hud = ProgressHudUtility()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customNavbar.screenTitle.text = "Settings"
        customNavbar.delegate = self
        configureCollectionView()
        setupGestures()
    }
    
    override func checkProStatus() {
        super.checkProStatus()
        proView.isHidden = AppDefaults.shared.isPremium
    }
    
    func setupGestures() {
        tryNowButton.addTapGestureRecognizer(target: self, action: #selector(tryNowButtonTap))
    }
    
    func configureCollectionView() {
        settingsCollectionView.register(SettingsCollectionViewCell.nib(), forCellWithReuseIdentifier: SettingsCollectionViewCell.Identifier)
        
        settingsCollectionView.dataSource = self
        settingsCollectionView.delegate = self
    }
    
    func restorePurchase() -> () {
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

//MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension SettingsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        settings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SettingsCollectionViewCell.Identifier,
            for: indexPath
        ) as? SettingsCollectionViewCell else { return UICollectionViewCell() }
        
        let setting = settings[indexPath.row]
        cell.configure(with: setting)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.item {
        case 1:
            if let url = URL(string: Constants.urlRate) {
                UIApplication.shared.open(url)
            }
        case 2:
            if let url = URL(string: Constants.urlAppStore) {
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityVC.excludedActivityTypes = [.saveToCameraRoll, .copyToPasteboard]
                
                activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                    if completed {
                        print("Sharing completed via \(activityType?.rawValue ?? "unknown")")
                    }
                }
                
                if Constants.currentDevice.model == "iPad" {
                    activityVC.popoverPresentationController?.sourceView = self.view
                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    activityVC.popoverPresentationController?.permittedArrowDirections = []
                }
                
                self.present(activityVC, animated: true, completion: nil)
            }
        case 3:
            if let url = URL(string: Constants.urlPrivacy) {
                UIApplication.shared.open(url)
            }
        case 4:
            if let url = URL(string: Constants.urlTerms) {
                UIApplication.shared.open(url)
            }
        case 5:
            if let url = URL(string: Constants.urlMoreApps) {
                UIApplication.shared.open(url)
            }
        case 6:
            restorePurchase()
        default:
            break
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension SettingsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 56)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        10
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        10
    }
}

//MARK: - SettingsCollectionViewCellDelegate
extension SettingsViewController: SettingsCollectionViewCellDelegate {
    func menuItemSelected() {
        self.settingsCollectionView.reloadData()
    }
}

//MARK: - CustomNavbarDelegate
extension SettingsViewController: CustomNavbarDelegate {
    func didTapProButton() {
        Utility.showPaywallScreen(caller: self)
    }
}

//MARK: - @objc Methods
extension SettingsViewController {
    @objc func tryNowButtonTap() {
        Utility.showPaywallScreen(caller: self)
    }
}

