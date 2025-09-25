import UIKit

protocol SecondaryCustomNavbarDelegate: AnyObject {
    func settingsButtonTapped()
}

class SecondaryCustomNavbar: UIView {
    
    @IBOutlet weak var screenTitle: UILabel!
    @IBOutlet weak var backButton: UIView!
    @IBOutlet weak var settingsButton: UIView!
    
    weak var delegate: SecondaryCustomNavbarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewLoad()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewLoad()
    }
    
    private func viewLoad() {
        let navbar = Bundle.main.loadNibNamed("SecondaryCustomNavbar", owner: self, options: nil)?.first as! UIView
        navbar.frame = self.bounds
        addSubview(navbar)
        
        setupGestures()
        settingsButton.isHidden = true
    }

    private func setupGestures() {
        backButton.addTapGestureRecognizer(target: self, action: #selector(backButtonTap))
        settingsButton.addTapGestureRecognizer(target: self, action: #selector(settingsButtonTap))
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}

//MARK: - @objc Methods

extension SecondaryCustomNavbar {
    @objc func backButtonTap() {
        if let viewController = findViewController() {
            if let navController = viewController.navigationController {
                if let vc = viewController as? ConversionViewController {
                    for file in vc.files {
                        if let resultURL = file.resultURL {
                            try? FileManager.default.removeItem(at: resultURL)
                        }
                    }
                    
                    if !vc.isResultScreen {
                        do {
                            let tempDirectory = FileManager.default.temporaryDirectory
                            let contents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
                            for item in contents {
                                try FileManager.default.removeItem(at: item)
                            }
                        } catch {
                            print("Failed to clean temporary directory: \(error)")
                        }
                    }
                }
                
                navController.popViewController(animated: true)
            }
        }
    }
    
    @objc func settingsButtonTap() {
        delegate?.settingsButtonTapped()
    }
}
