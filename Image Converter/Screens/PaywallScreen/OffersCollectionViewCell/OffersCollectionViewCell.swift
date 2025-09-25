import UIKit

class OffersCollectionViewCell: UICollectionViewCell {
    
    static let Identifier = "OffersCollectionViewCell"

    @IBOutlet weak var radioButton: UIView!
    @IBOutlet weak var innerRadioButton: UIView!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var averageLabel: UILabel!
    @IBOutlet weak var offerTypeContainer: UIView!
    @IBOutlet weak var offerTypeLabel: UILabel!
    @IBOutlet weak var cellContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func attributedAverageText(_ text: String) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: UIColor.red,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: UIColor.red
            ]
        )
    }
    
    func configSelection(isSelected: Bool){
        innerRadioButton.backgroundColor = isSelected ? UIColor(named: "Primary") : .clear
        cellContainer.backgroundColor = isSelected ? UIColor(named: "Upload Background") : .clear
        cellContainer.layer.borderColor = isSelected ? UIColor(named: "Primary")?.cgColor : UIColor(named: "Tabbar Border")?.cgColor
    }
    
    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }

}
