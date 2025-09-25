import UIKit

class AspectsCollectionViewCell: UICollectionViewCell {
    
    static let Identifier = "AspectsCollectionViewCell"
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(named: "Tabbar Border")?.cgColor
    }
    
    public func configure(with aspect: Aspect) {
        imageView.image = aspect.image
        labelView.text = aspect.title
    }
    
    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
}
