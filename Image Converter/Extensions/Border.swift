//
//  Border.swift
//  Fashion-Ai
//
//  Created by Macbook Pro on 22/02/2025.
//

import UIKit

extension UIView {
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func addBottomBorder(color: UIColor, height: CGFloat, gap: CGFloat) {
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = color
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(bottomBorder)
        
        NSLayoutConstraint.activate([
            bottomBorder.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -gap),
            bottomBorder.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: height)
        ])
    }
    
    func addTopBorder(color: UIColor, height: CGFloat) {
        let topBorder = UIView()
        topBorder.backgroundColor = color
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(topBorder)
        
        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: self.topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: height)
        ])
    }
}
