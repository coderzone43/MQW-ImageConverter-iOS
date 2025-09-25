import UIKit

class CompressSettingsViewController: UIViewController {
    
    @IBOutlet weak var dismissContainer: UIView!
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var compressionQualitySlider: UISlider!
    @IBOutlet weak var compressionQualityLabel: UILabel!
    @IBOutlet weak var saveButton: UIView!
    
    var compression: Int?
    var onDismiss: ((Int?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        compressionQualitySlider.minimumValue = 0
        compressionQualitySlider.maximumValue = 100
        compressionQualitySlider.value = compression == nil ? 0 : Float(compression!)
        
        compression = compression ?? 0
        updateCompressionLabel()
        
        compressionQualitySlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        setupGestures()
    }
    
    func setupGestures() {
        closeButton.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        dismissContainer.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        saveButton.addTapGestureRecognizer(target: self, action: #selector(saveButtonTap))
    }
    
    func updateCompressionLabel() {
        if let compressionValue = compression {
            compressionQualityLabel.text = "\(compressionValue)%"
        }
    }
}

//MARK: - @objc Methods

extension CompressSettingsViewController {
    @objc func closeButtonTap() {
        dismiss(animated: true)
    }
    
    @objc func saveButtonTap() {
        if compressionQualitySlider.value == 0 {
            compression = nil
        }
        
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?(self?.compression)
        }
    }
    
    @objc func sliderValueChanged(_ slider: UISlider) {
        let value = Int(slider.value)
        compression = value
        updateCompressionLabel()
    }
}
