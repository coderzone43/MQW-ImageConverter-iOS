import UIKit

extension UIView {
    func asImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        return renderer.image { context in
            self.layer.render(in: context.cgContext)
        }
    }
    
    func addTapGestureRecognizer(target: Any, action: Selector) {
        isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: target, action: action)
        addGestureRecognizer(tapGestureRecognizer)
    }
}

