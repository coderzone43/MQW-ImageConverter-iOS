import UIKit

class ReviewViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIView!
    @IBOutlet weak var reviewButton: UIView!
    @IBOutlet weak var emailButton: UILabel!
    
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
    }
    
    func setupGestures() {
        cancelButton.addTapGestureRecognizer(target: self, action: #selector(cancelButtonTap))
        emailButton.addTapGestureRecognizer(target: self, action: #selector(emailButtonTap))
        reviewButton.addTapGestureRecognizer(target: self, action: #selector(reviewButtonTap))
    }
}

//MARK: - @objc Methods
extension ReviewViewController {
    @objc func cancelButtonTap() {
        self.dismiss(animated: true) {
            self.onDismiss?()
        }
    }
    
    @objc func emailButtonTap() {
        if let url = URL(string: Constants.supportEmail) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func reviewButtonTap() {
        if let url = URL(string: Constants.urlRate) {
            UIApplication.shared.open(url)
            AppDefaults.shared.reviewRequested = true
        }
    }
}
