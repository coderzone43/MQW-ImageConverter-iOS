import UIKit

class TabBarNavController: UITabBarController {
    
    @IBOutlet weak var customTabbar: UITabBar!
    
    override func viewWillAppear(_ animated: Bool) {
        if let navigationController = self.navigationController {
            navigationController.navigationBar.isHidden = true
            navigationController.setNavigationBarHidden(true, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #unavailable(iOS 26.0) {
            addTopBorder()
        } else {
            tabBar.isTranslucent = true
        }
    }
    
    func addTopBorder() {
        let borderView = UIView()
        borderView.frame = CGRect(x: 0, y: -1.5, width: self.tabBar.frame.size.width, height: 1.5)
        borderView.backgroundColor = UIColor(named: "Tabbar Border")
        borderView.autoresizingMask = [.flexibleWidth]
        customTabbar.addSubview(borderView)
    }
}




