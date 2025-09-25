//
//  BaseVC.swift
//  Image Converter
//
//  Created by Macbook Pro on 23/09/2025.
//

import UIKit

class BaseVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(checkProStatus), name: .IAPHelperPurchaseNotification, object: nil)
        checkProStatus()
    }
    
    
}
//MARK: - Objective C Functions Extension
@objc extension BaseVC{
    func checkProStatus(){}
}
