//
//  Extentions.swift
//  Fashion-Ai
//
//  Created by Macbook Pro on 17/02/2025.
//

import UIKit

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var topCornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            self.clipsToBounds = true
            self.layer.cornerRadius = newValue
            // Apply radius to the top corners
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }

    @IBInspectable var bottomCornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            self.clipsToBounds = true
            self.layer.cornerRadius = newValue
            // Apply radius to the bottom corners
            self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }

    @IBInspectable var leftCornerRadius: CGFloat {
            get {
                return layer.cornerRadius
            }
            set {
                self.clipsToBounds = true
                self.layer.cornerRadius = newValue
                self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            }
        }

        @IBInspectable var rightCornerRadius: CGFloat {
            get {
                return layer.cornerRadius
            }
            set {
                self.clipsToBounds = true
                self.layer.cornerRadius = newValue
                self.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            }
        }
    
    @IBInspectable var isCircle: Bool {
        get {
            return layer.cornerRadius == min(bounds.width, bounds.height) / 2
        }
        set {
            if newValue {
                // Ensure the cornerRadius is half of the smaller dimension (either width or height)
                let minDimension = min(bounds.width, bounds.height)
                layer.cornerRadius = minDimension / 2
                layer.masksToBounds = true
            } else {
                // Set cornerRadius to 0 if the circle property is false
                layer.cornerRadius = 0
                layer.masksToBounds = false
            }
        }
    }

     @IBInspectable var makeCircleRadius: Bool {
         get {
             return layer.cornerRadius == layer.frame.height / 2
         }
         set {
             if newValue {
                 let minDimension = min(bounds.width, bounds.height)
                 layer.cornerRadius = minDimension / 2
                 layer.masksToBounds = true
             } else {
                 layer.cornerRadius = 0
             }
         }
     }
    func roundTopCorners(view: UIView, radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: view.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        view.layer.mask = mask
    }

    func roundBottomCorners(view: UIView, radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: view.bounds,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        view.layer.mask = mask
    }
    func addTapGesture(target: Any,selector: Selector){
        isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: target, action: selector)
        addGestureRecognizer(gesture)
    }
}
