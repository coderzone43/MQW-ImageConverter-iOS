import UIKit

protocol ImageWatermarkContainerDelegate: AnyObject {
    func watermarkContainerDidCancel(_ container: ImageWatermarkContainer)
}

class ImageWatermarkContainer: UIView {
    
    private var contentView: UIView?
    private let borderLayer = CAShapeLayer()
    weak var delegate: ImageWatermarkContainerDelegate?
    var onBorderVisibilityChanged: ((Bool) -> Void)?
    
    private let cancelButton = UIButton(type: .custom)
    private let rotateButton = UIButton(type: .custom)
    private let resizeButton = UIButton(type: .custom)
    
    private var initialSize: CGSize = CGSize(width: 148, height: 106)
    private let buttonSize: CGFloat = 24
    
    var isSelected: Bool = false {
        didSet {
            toggleBorderVisibility()
        }
    }
    
    private let imageView = UIImageView()
    
    convenience init(withImage image: UIImage) {
        self.init(frame: CGRect(origin: .zero, size: CGSize(width: 148, height: 106)))
        setImage(image)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame.isEmpty ? CGRect(origin: .zero, size: initialSize) : frame)
        setupViews()
        setupGestures()
        setupBorder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGestures()
        setupBorder()
    }
    
    private func setupViews() {
        clipsToBounds = false
        
        // Setup image view
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .clear
        addSubview(imageView)
        contentView = imageView
        
        // Cancel button
        cancelButton.frame = CGRect(x: -12, y: -12, width: buttonSize, height: buttonSize)
        cancelButton.backgroundColor = UIColor(named: "Primary")
        cancelButton.layer.cornerRadius = buttonSize / 2
        cancelButton.setImage(UIImage(named: "Watermark-Close") ?? UIImage(systemName: "xmark"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.addTarget(self, action: #selector(removeSelf), for: .touchUpInside)
        addSubview(cancelButton)
        
        // Rotate button
        rotateButton.frame = CGRect(x: bounds.width - buttonSize + 12, y: -12, width: buttonSize, height: buttonSize)
        rotateButton.backgroundColor = UIColor(named: "Primary")
        rotateButton.layer.cornerRadius = buttonSize / 2
        rotateButton.setImage(UIImage(named: "Watermark-Rotate") ?? UIImage(systemName: "rotate.right"), for: .normal)
        rotateButton.tintColor = .white
        addSubview(rotateButton)
        
        // Resize button
        resizeButton.frame = CGRect(x: bounds.width - buttonSize + 12, y: bounds.height - buttonSize + 12, width: buttonSize, height: buttonSize)
        resizeButton.backgroundColor = UIColor(named: "Primary")
        resizeButton.layer.cornerRadius = buttonSize / 2
        resizeButton.setImage(UIImage(named: "Watermark-Resize") ?? UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        resizeButton.tintColor = .white
        addSubview(resizeButton)
    }
    
    private func setupGestures() {
        resizeButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleResize(_:))))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDrag(_:))))
        rotateButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleRotate(_:))))
        imageView.addTapGestureRecognizer(target: self, action: #selector(updateImageViewOnSelection))
    }
    
    private func setupBorder() {
        borderLayer.strokeColor = UIColor(named: "Primary")?.cgColor
        borderLayer.lineWidth = 1
        borderLayer.lineDashPattern = [6, 3]
        borderLayer.fillColor = nil
        layer.addSublayer(borderLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(rect: bounds).cgPath
        
        imageView.frame = bounds
        contentView?.frame = bounds
        
        cancelButton.frame = CGRect(x: -12, y: -12, width: buttonSize, height: buttonSize)
        rotateButton.frame = CGRect(x: bounds.width - buttonSize + 12, y: -12, width: buttonSize, height: buttonSize)
        resizeButton.frame = CGRect(x: bounds.width - buttonSize + 12, y: bounds.height - buttonSize + 12, width: buttonSize, height: buttonSize)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let parent = superview {
            center = CGPoint(x: parent.bounds.midX, y: parent.bounds.midY)
        }
    }
    
    func setImage(_ image: UIImage) {
        contentView?.removeFromSuperview()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        contentView = imageView
        bringSubviewToFront(cancelButton)
        bringSubviewToFront(rotateButton)
        bringSubviewToFront(resizeButton)
        setNeedsLayout()
    }
    
    func imageSettingsChanged(opacity: Float?) {
        if let opacity = opacity {
            imageView.alpha = CGFloat(opacity/100)
        }
    }
    
    // Calculate the effective size of the rotated view's bounding box
    private func calculateEffectiveSize(width: CGFloat, height: CGFloat, rotation: CGFloat) -> CGSize {
        let cosAngle = abs(cos(rotation))
        let sinAngle = abs(sin(rotation))
        let effectiveWidth = width * cosAngle + height * sinAngle
        let effectiveHeight = width * sinAngle + height * cosAngle
        return CGSize(width: effectiveWidth, height: effectiveHeight)
    }
    
    // Calculate maximum allowed dimensions to keep the view within superview bounds
    private func calculateMaxDimension(currentCenter: CGPoint, superviewSize: CGSize, rotation: CGFloat) -> CGSize {
        let cosAngle = abs(cos(rotation))
        let sinAngle = abs(sin(rotation))
        
        // Maximum width and height based on center position
        let maxWidthAtX = (superviewSize.width - 2 * abs(currentCenter.x - superviewSize.width / 2)) / (cosAngle + sinAngle)
        let maxHeightAtY = (superviewSize.height - 2 * abs(currentCenter.y - superviewSize.height / 2)) / (cosAngle + sinAngle)
        
        return CGSize(width: maxWidthAtX, height: maxHeightAtY)
    }
    
    private func toggleBorderVisibility() {
        if isSelected {
            borderLayer.isHidden = false
            cancelButton.isHidden = false
            rotateButton.isHidden = false
            resizeButton.isHidden = false
        } else {
            borderLayer.isHidden = true
            cancelButton.isHidden = true
            rotateButton.isHidden = true
            resizeButton.isHidden = true
        }
        onBorderVisibilityChanged?(isSelected)
    }
}

//MARK: - @objc Methods
extension ImageWatermarkContainer {
    @objc private func updateImageViewOnSelection() {
        isSelected = true
    }
    
    @objc private func removeSelf() {
        delegate?.watermarkContainerDidCancel(self)
    }
    
    @objc private func handleResize(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        if gesture.state == .changed {
            let translation = gesture.translation(in: self)
            let rotationAngle = atan2(transform.b, transform.a)
            let cosAngle = cos(-rotationAngle)
            let sinAngle = sin(-rotationAngle)
            let transformedX = translation.x * cosAngle + translation.y * sinAngle
            let transformedY = -translation.x * sinAngle + translation.y * cosAngle
            var newWidth = bounds.width + transformedX
            var newHeight = bounds.height + transformedY
            newWidth = max(newWidth, 50)
            newHeight = max(newHeight, 50)
            let currentCenter = center
            let effectiveSize = calculateEffectiveSize(width: newWidth, height: newHeight, rotation: rotationAngle)
            let minX = effectiveSize.width / 2
            let maxX = superview.bounds.width - effectiveSize.width / 2
            let minY = effectiveSize.height / 2
            let maxY = superview.bounds.height - effectiveSize.height / 2
            if currentCenter.x < minX || currentCenter.x > maxX || currentCenter.y < minY || currentCenter.y > maxY {
                let maxWidth = calculateMaxDimension(currentCenter: currentCenter, superviewSize: superview.bounds.size, rotation: rotationAngle).width
                let maxHeight = calculateMaxDimension(currentCenter: currentCenter, superviewSize: superview.bounds.size, rotation: rotationAngle).height
                newWidth = min(newWidth, maxWidth)
                newHeight = min(newHeight, maxHeight)
            }
            
            bounds.size = CGSize(width: newWidth, height: newHeight)
            var newCenter = currentCenter
            newCenter.x = max(minX, min(newCenter.x, maxX))
            newCenter.y = max(minY, min(newCenter.y, maxY))
            center = newCenter
            
            gesture.setTranslation(.zero, in: self)
        }
    }
    
    @objc private func handleDrag(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        if gesture.state == .changed {
            isSelected = true
            let translation = gesture.translation(in: superview)
            var newCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            let rotationAngle = atan2(transform.b, transform.a)
            let effectiveSize = calculateEffectiveSize(width: bounds.width, height: bounds.height, rotation: rotationAngle)
            let minX = effectiveSize.width / 2
            let maxX = superview.bounds.width - effectiveSize.width / 2
            let minY = effectiveSize.height / 2
            let maxY = superview.bounds.height - effectiveSize.height / 2
            
            newCenter.x = max(minX, min(newCenter.x, maxX))
            newCenter.y = max(minY, min(newCenter.y, maxY))
            
            center = newCenter
            gesture.setTranslation(.zero, in: superview)
        }
    }
    
    @objc private func handleRotate(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        if gesture.state == .changed {
            let location = gesture.location(in: superview)
            let centerPoint = center
            
            let deltaX = location.x - centerPoint.x
            let deltaY = location.y - centerPoint.y
            let angle = atan2(deltaY, deltaX)
            
            transform = CGAffineTransform(rotationAngle: angle)
            rotateButton.center = CGPoint(x: bounds.width, y: 0)
        }
    }
}
