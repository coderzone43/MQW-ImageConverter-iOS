import Foundation
import UIKit

@IBDesignable
class CustomGradientBorderView: UIView {
    
    // MARK: - Inspectable Properties
    @IBInspectable var cornerRadiusFor: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadiusFor
            gradientLayer.cornerRadius = cornerRadiusFor
        }
    }
    
    @IBInspectable var borderWidthFor: CGFloat = 2.0 {
        didSet {
            updateBorder()
        }
    }
    
    @IBInspectable var dashPattern: CGFloat = 6.0 {
        didSet {
            updateBorder()
        }
    }
    
    @IBInspectable var dashSpacing: CGFloat = 4.0 {
        didSet {
            updateBorder()
        }
    }
    
    @IBInspectable var startColor: UIColor = .red {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable var endColor: UIColor = .blue {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable var startPoint: CGPoint = CGPoint(x: 0, y: 0.5) {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable var endPoint: CGPoint = CGPoint(x: 1, y: 0.5) {
        didSet {
            updateGradient()
        }
    }
    
    // MARK: - Layers
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
        updateBorder()
    }
    
    // MARK: - Setup Methods
    private func setupView() {
        layer.masksToBounds = true
        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
    }
    
    private func updateGradient() {
        gradientLayer.frame = bounds
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
    
    private func updateBorder() {
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadiusFor).cgPath
        
        shapeLayer.path = path
        shapeLayer.lineWidth = borderWidthFor
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineDashPattern = [NSNumber(value: Float(dashPattern)), NSNumber(value: Float(dashSpacing))]
        shapeLayer.frame = bounds
    }
}
