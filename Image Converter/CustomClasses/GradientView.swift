import UIKit

class GradientView: UIView {
    private var gradientLayer: CAGradientLayer!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            gradientLayer.locations = [0.0, 0.4]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
        
        gradientLayer.frame = self.bounds
        updateGradient()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        layoutSubviews()
        updateGradient()
    }
    
    private func updateGradient() {
        if self.traitCollection.userInterfaceStyle == .dark {
            gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        } else {
            gradientLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
        }
    }
}
