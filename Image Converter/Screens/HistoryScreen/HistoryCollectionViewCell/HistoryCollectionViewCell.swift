import UIKit

protocol HistoryCollectionViewCellDelegate: AnyObject {
    func historyCollectionViewCellSettingsButtonTapped(_ cell: HistoryCollectionViewCell, history: CDHistory)
    func historyCollectionViewImageViewTapped(_ cell: HistoryCollectionViewCell, history: CDHistory, url: URL)
}

class HistoryCollectionViewCell: UICollectionViewCell {
    
    static let Identifier = "HistoryCollectionViewCell"
    weak var delegate: HistoryCollectionViewCellDelegate?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var settingsButton: UIImageView!
    
    var history: CDHistory?
    var thumbnail = ThumbnailGenerator()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if Constants.currentDevice.model == "iPad" {
            imageView.contentMode = .scaleAspectFit
        }
        
        addSettingsButtonTap()
    }
    
    func addSettingsButtonTap() {
        settingsButton.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(settingsButtonTap))
        settingsButton.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func loadImage(named name: String?) -> UIImage {
        var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory.appendPathComponent(name ?? "")
        
        if let image = UIImage(contentsOfFile: directory.path) {
            return image
        } else {
            print("Failed to load image from URL: \(directory)")
            return UIImage()
        }
    }
    
    func loadThumbnail(named name: String?) {
        var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory.appendPathComponent(name ?? "")
        
        thumbnail.getThumbnail(for: directory, size: imageView.frame.size, scale: UIScreen.main.scale) { [weak self] (thumbnailImage, error) in
            
            if let self, let thumbnailImage {
                self.imageView.image = thumbnailImage
            }
            
        }
    }
    
    func addImageViewTap(_ selector: Selector) {
        imageView.isUserInteractionEnabled = true
        imageView.addTapGestureRecognizer(target: self, action: selector)
    }
    
    func configure(with history: CDHistory) {
        self.history = history
        if history.category == ConversionCategory.imageToImage.rawValue {
            imageView.image = loadImage(named: history.title)
            addImageViewTap(#selector(imageViewTap))
        } else if history.category == ConversionCategory.imageToPDF.rawValue {
            loadThumbnail(named: history.title)
            addImageViewTap(#selector(imageViewTap))
        } else if history.category == ConversionCategory.imageToZip.rawValue || history.category == ConversionCategory.pdfToImage.rawValue  {
            imageView.image = UIImage.convertToZipIcon
        } else if history.category == ConversionCategory.imageToText.rawValue {
            imageView.image = UIImage.extractTextIcon
            addImageViewTap(#selector(imageViewTap))
        }
        
        nameLabel.text = history.title
        typeLabel.text = history.type.uppercased()
        let sizeInKB = Double(history.size) / 1024.0
        sizeLabel.text = "\(String(format: "%.2f KB", sizeInKB))"
    }
    
    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
    
    private var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}

extension HistoryCollectionViewCell: UIDocumentInteractionControllerDelegate {
    
}

//MARK: - @objc Methods
extension HistoryCollectionViewCell {
    @objc func settingsButtonTap() {
        guard let history else { return }
        delegate?.historyCollectionViewCellSettingsButtonTapped(self, history: history)
    }
    
    @objc func imageViewTap() {
        guard let history else { return }
        var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory.appendPathComponent(history.title)
        delegate?.historyCollectionViewImageViewTapped(self, history: history, url: directory)
    }
}
