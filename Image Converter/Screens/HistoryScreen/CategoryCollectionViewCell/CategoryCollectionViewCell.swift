import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {

    static let Identifier = "CategoryCollectionViewCell"
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var labelView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func configure(with name: String) {
        labelView.text = name
    }

    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
    
    override var isSelected: Bool {
        didSet {
            labelView.textColor = isSelected ? .white : .offerLabel
            container.backgroundColor = isSelected ? .primary : .searchBar
        }
    }
}
