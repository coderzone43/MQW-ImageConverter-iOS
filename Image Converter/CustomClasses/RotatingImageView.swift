import UIKit

class RotatingImageView: UIImageView {
    
    var rotationAngle: CGFloat = 0 {
        didSet {
            transformImage()
        }
    }
    
    var flipHorizontal: Bool = false {
        didSet {
            transformImage()
        }
    }
    
    var flipVertical: Bool = false {
        didSet {
            transformImage()
        }
    }
    
    func transformImage() {
        guard let image = image else { return }
        
        let bounds = self.bounds
        let imageSize = image.size
        var transform = CGAffineTransform.identity
        
        if flipHorizontal { transform = transform.scaledBy(x: -1, y: 1) }
        if flipVertical { transform = transform.scaledBy(x: 1, y: -1) }
        
        transform = transform.rotated(by: rotationAngle * (.pi / 180))
        self.transform = transform
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let drawWidth = imageSize.width * scale
        let drawHeight = imageSize.height * scale
        
        let drawRect = CGRect(x: (bounds.width - drawWidth) / 2,
                              y: (bounds.height - drawHeight) / 2,
                              width: drawWidth,
                              height: drawHeight)
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        image.draw(in: drawRect)
        let transformedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = transformedImage
    }
}
