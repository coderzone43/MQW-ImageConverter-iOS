import UIKit

class RotatingCollectionViewCell: UICollectionViewCell {
    
    static let Identifier = "RotatingCollectionViewCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func configure(with item: RotatingItem) {
        imageView.image = item.image
        labelView.text = item.label
    }

    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
}
