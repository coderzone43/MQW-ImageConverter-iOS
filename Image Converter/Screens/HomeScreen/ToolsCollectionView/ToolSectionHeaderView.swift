import UIKit

class ToolSectionHeaderView: UICollectionViewCell {
    
    static let Identifier = "ToolSectionHeaderView"

    @IBOutlet weak var sectionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
}
