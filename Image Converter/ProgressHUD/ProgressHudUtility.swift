//
//  ProgressHudUtility.swift
//  Image Converter
//
//  Created by Macbook Pro on 17/09/2025.
//

import Foundation
import UIKit


class ProgressHudUtility{
    
    var hud: MBProgressHUD?
    init(){
        hud = MBProgressHUD()
    }
    @MainActor
    func showHUD(on view: UIView){
        DispatchQueue.main.async { [weak self] in
            guard let self else{return}
            self.hud = MBProgressHUD.showAdded(to: view, animated: true)
            self.hud?.bezelView.color = .black
            self.hud?.animationType = .zoomOut
            self.hud?.activityIndicatorColor = .white
        }
    }

    func showHUD(on view: UIView, with message: String) {
        DispatchQueue.main.async {[weak self] in
            guard let self = self else {return}
            self.hud = MBProgressHUD.showAdded(to: view, animated: true)
                   self.hud?.label.text = message
        }
    }
    func showHUDWithCancel(on view: UIView, with message: String) {
           self.hud = MBProgressHUD.showAdded(to: view, animated: true)
           self.hud?.label.text = message
           self.hud?.mode = .determinate
        self.hud?.button.setTitle("Stop", for: .normal)
           self.hud?.button.addTarget(self, action: #selector(cancelButton), for: .touchUpInside)
           
       }

    func showHUDWithCancelWithoutProgress(on view: UIView, with message: String) {
              self.hud = MBProgressHUD.showAdded(to: view, animated: true)
              self.hud?.label.text = message
              //self.hud?.mode = .determinate
        self.hud?.button.setTitle("Stop", for: .normal)
              self.hud?.button.addTarget(self, action: #selector(cancelButton), for: .touchUpInside)
              
          }

    @objc func cancelButton(tabBarController: UITabBarController?) {
           self.hud?.hide(animated: true)
       }
    @MainActor
    func hideHUD() -> Void {
        DispatchQueue.main.async { [weak self] in
            guard let self else{return}
            self.hud?.hide(animated: true)
        }
    }
    func setProgress(_ progress: Float){
        self.hud?.progress = progress
    }
    
    
    // MARK :- Show/Hide Huds with Enable/Disable Tab Bar items
    func showHUDDisableTabBarItem(on view: UIView, with message: String?) {
              self.hud = MBProgressHUD.showAdded(to: view, animated: true)
        self.hud?.layer.zPosition = CGFloat(Int.max)
        view.bringSubviewToFront(self.hud!)
        if let message = message {
            self.hud?.label.text = message
            self.hud?.button.setTitle("Stop", for: .normal)
                  self.hud?.button.addTarget(self, action: #selector(cancelButton), for: .touchUpInside)
        }
    }
}
