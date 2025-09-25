import UIKit

@IBDesignable
class RadioButton: UIControl {
    private weak var imageView: UIImageView!
    
    private var image: UIImage {
        return checked ? UIImage(systemName: "circle.fill")! : UIImage(systemName: "circle")!
    }
    
    @IBInspectable
    public var checked: Bool = false {
        didSet {
            imageView?.image = image
            sendActions(for: .valueChanged)
        }
    }
    
    // Optional: Group identifier to manage mutually exclusive selection
    @IBInspectable
    public var groupId: String = "" {
        didSet {
            updateGroupSelection()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.contentMode = .scaleAspectFit
        self.imageView = imageView
        imageView.image = image
        backgroundColor = UIColor.clear
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }
    
    @objc func touchUpInside() {
        guard !checked else { return } // Prevent deselecting a selected radio button
        checked = true
        updateGroupSelection()
    }
    
    private func updateGroupSelection() {
        if !groupId.isEmpty, checked {
            if let superview = superview {
                for case let radioButton as RadioButton in superview.subviews {
                    if radioButton !== self && radioButton.groupId == groupId {
                        radioButton.checked = false
                    }
                }
            }
        }
    }
}
