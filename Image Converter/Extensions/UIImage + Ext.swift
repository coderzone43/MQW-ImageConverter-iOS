import UIKit

extension UIImage {
    /// Resize into a fixed canvas (`targetSize`).
    /// - If `aspectFit == true`: scales the image to fit inside the canvas and centers it,
    ///   leaving transparent (or colored) padding in the empty regions.
    /// - If `aspectFit == false`: stretches to fill the canvas (no padding).
    /// - `scale` controls the UIImage scale (set 1.0 to avoid 3x upscaling like 300→100*3).
    /// - `backgroundColor`: if non-nil, fills the canvas before drawing (set `opaque = true` to avoid alpha).
    func resized(to targetSize: CGSize, aspectFit: Bool, scale: CGFloat = 1.0, backgroundColor: UIColor? = nil) -> UIImage? {
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = (backgroundColor != nil)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        return renderer.image { ctx in
            if let bg = backgroundColor {
                bg.setFill()
                ctx.fill(CGRect(origin: .zero, size: targetSize))
            } else {
                ctx.cgContext.clear(CGRect(origin: .zero, size: targetSize))
            }
            
            let drawRect: CGRect
            if aspectFit {
                let widthRatio  = targetSize.width  / self.size.width
                let heightRatio = targetSize.height / self.size.height
                let scaleFactor = min(widthRatio, heightRatio)
                let newW = self.size.width  * scaleFactor
                let newH = self.size.height * scaleFactor
                let x = (targetSize.width  - newW) * 0.5
                let y = (targetSize.height - newH) * 0.5
                
                drawRect = CGRect(x: x, y: y, width: newW, height: newH).integral
            } else {
                drawRect = CGRect(origin: .zero, size: targetSize).integral
            }
            
            self.draw(in: drawRect)
        }
    }
}
