import UIKit

class ColorsCollectionViewCell: UICollectionViewCell {

    static let Identifier = "ColorsCollectionViewCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        imageView.isHidden = true
        super.awakeFromNib()
    }
    
    func configure(with color: UIColor) {
        containerView.backgroundColor = color
    }
    
    func lastCell() {
        imageView.isHidden = false
    }
    
    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
    
    override var isSelected: Bool {
        didSet {
            containerView.layer.borderWidth = isSelected ? 2 : 0
            containerView.layer.borderColor = isSelected ? UIColor(named: "Primary")?.cgColor : nil
        }
    }
}
