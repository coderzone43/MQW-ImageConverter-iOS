import UIKit

class SlideInFromRightAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.45
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        
        if isPresenting {
            guard let toView = transitionContext.view(forKey: .to) else { return }
            
            let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
            toView.frame = finalFrame.offsetBy(dx: finalFrame.width, dy: 0)
            container.addSubview(toView)
            
            let backgroundView = UIView(frame: finalFrame)
            backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            backgroundView.tag = 999
            toView.insertSubview(backgroundView, at: 0)
            
            UIView.animate(withDuration: 0.35, animations: {
                toView.frame = finalFrame
            }, completion: { finished in
                UIView.animate(withDuration: 0.1) {
                    backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                }
                transitionContext.completeTransition(finished)
            })
            
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else { return }
            
            let finalFrame = fromView.frame.offsetBy(dx: fromView.frame.width, dy: 0)
            
            if let backgroundView = fromView.subviews.first(where: { $0.tag == 999 }) {
                UIView.animate(withDuration: 0.1, animations: {
                    backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.35, animations: {
                        fromView.frame = finalFrame
                    }, completion: { finished in
                        backgroundView.removeFromSuperview()
                        transitionContext.completeTransition(finished)
                    })
                })
            } else {
                UIView.animate(withDuration: 0.35, animations: {
                    fromView.frame = finalFrame
                }, completion: { finished in
                    transitionContext.completeTransition(finished)
                })
            }
        }
    }
}
