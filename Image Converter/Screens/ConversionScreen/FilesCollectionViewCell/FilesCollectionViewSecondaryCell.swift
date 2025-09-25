import UIKit

protocol FilesCollectionViewSecondaryCellDelegate: AnyObject {
    func cancelButtonTap(_ cell: FilesCollectionViewSecondaryCell)
}

class FilesCollectionViewSecondaryCell: UICollectionViewCell {

    static let Identifier = "FilesCollectionViewSecondaryCell"
    weak var delegate: FilesCollectionViewSecondaryCellDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGestures()
    }
    
    public func configure(with image: UIImage) {
        imageView.image = image
    }
    
    private func setupGestures() {
        cancelButton.addTapGestureRecognizer(target: self, action: #selector(cancelButtonTap))
    }

    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
}

//MARK: - @objc Methods
extension FilesCollectionViewSecondaryCell {
    @objc private func cancelButtonTap() {
        delegate?.cancelButtonTap(self)
    }
}
