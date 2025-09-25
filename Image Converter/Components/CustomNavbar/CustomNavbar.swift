import UIKit

protocol CustomNavbarDelegate: AnyObject {
    func didTapProButton()
}

class CustomNavbar: UIView {
    
    @IBOutlet weak var screenTitle: UILabel!
    @IBOutlet weak var proButton: UIView!
    
    weak var delegate: CustomNavbarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewLoad()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewLoad()
    }
    
    private func viewLoad() {
        let navbar = Bundle.main.loadNibNamed("CustomNavbar", owner: self, options: nil)?.first as! UIView
        navbar.frame = self.bounds
        addSubview(navbar)
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkProStatus), name: .IAPHelperPurchaseNotification, object: nil)
        prepareForAppearance()
        setupGestures()
    }
    
    private func setupGestures() {
        proButton.addTapGestureRecognizer(target: self, action: #selector(proButtonTap))
    }
    
    private func prepareForAppearance() {
        proButton.isHidden = AppDefaults.shared.isPremium
    }
}

//MARK: - @objc Functions

extension CustomNavbar {
    @objc func proButtonTap() {
        delegate?.didTapProButton()
    }
    
    @objc func checkProStatus() {
        prepareForAppearance()
    }
}
