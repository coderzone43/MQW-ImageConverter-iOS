import UIKit

class NoTextAlert: UIAlertController {
    
    convenience init(singleFile: Bool) {
        self.init(title: "", message: "No text found in the selected image" + (singleFile ? "." : "s."), preferredStyle: .alert)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(white: 1, alpha: 0.3)
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        
        let okAction = UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        addAction(okAction)
    }
    
    func present(from viewController: UIViewController) {
        viewController.present(self, animated: true)
    }
}
