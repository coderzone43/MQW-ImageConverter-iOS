import UIKit

protocol FilesCollectionViewCellDelegate: AnyObject {
    func cancelButtonTap(_ cell: FilesCollectionViewCell)
}

class FilesCollectionViewCell: UICollectionViewCell {
    
    static let Identifier = "FilesCollectionViewCell"
    weak var delegate: FilesCollectionViewCellDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelView: UILabel!
    @IBOutlet weak var cancelButton: UIImageView!
    @IBOutlet weak var textContainer: UIView!
    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGestures()
        textContainer.isHidden = true
    }
    
    public func configure(with image: UIImage, name: String, text: String? = nil, _ isResultCell: Bool) {
        imageView.image = image
        labelView.text = name
        cancelButton.isHidden = isResultCell
        
        if let text = text {
            textContainer.isHidden = false
            textLabel.text = text != "" ? text : "No text found"
        }
    }
    
    private func setupGestures() {
        cancelButton.addTapGestureRecognizer(target: self, action: #selector(cancelButtonTap))
    }
    
    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }

}

//MARK: - @objc Methods
extension FilesCollectionViewCell {
    @objc private func cancelButtonTap() {
        delegate?.cancelButtonTap(self)
    }
}
