import UIKit

class ToolCollectionViewCell: UICollectionViewCell {
    
    static let Identifier = "ToolCollectionViewCell"

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var toolImageView: UIImageView!
    @IBOutlet weak var toolLabelView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func configure(with image: UIImage, name: String) {
        toolImageView.image = image
        toolLabelView.text = name
    }

    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }

}
