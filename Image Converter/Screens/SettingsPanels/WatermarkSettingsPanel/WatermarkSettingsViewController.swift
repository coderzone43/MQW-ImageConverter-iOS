import UIKit

// MARK: - Data Structures and Protocols

struct WatermarkSettings {
    var textMode: Bool
    var imageMode: Bool
    var textField: String?
    var textOpacity: Float?
    var textFont: String?
    var textColor: UIColor?
    var image: UIImage?
    var imageOpacity: Float?
}

protocol WatermarkSettingsViewControllerDelegate: AnyObject {
    func textFieldDidChange(_ textField: String?)
    func textSettingsChanged(opacity: Float?, font: String?, color: UIColor?)
    func selectedImageChanged(_ image: UIImage?)
    func imageSettingsChanged(opacity: Float?)
}

// MARK: - WatermarkSettingsViewController

class WatermarkSettingsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var viewController: UISegmentedControl!
    @IBOutlet weak var dismissContainer: UIView!
    @IBOutlet weak var saveButton: UIView!
    
    @IBOutlet weak var textContainer: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var opacityLabel: UILabel!
    @IBOutlet weak var opacitySlider: UISlider!
    @IBOutlet weak var fontButton: UIButton!
    @IBOutlet weak var fontLabel: UILabel!
    @IBOutlet weak var colorsCollectonView: UICollectionView!
    
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var selectedImageContainer: UIView!
    @IBOutlet weak var selectedImageCancelButton: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var uploadImageButton: UIView!
    @IBOutlet weak var imageOpacityLabel: UILabel!
    @IBOutlet weak var imageOpacitySlider: UISlider!
    
    // MARK: - Properties
    
    private var fontsMenuButton: UIButton!
    private var selectedFont: Font = Fonts.first(where: { $0.fontName == "Raleway" })!
    private var selectedColor: UIColor?
    weak var delegate: WatermarkSettingsViewControllerDelegate?
    var modifiedSettings: WatermarkSettings?
    var onDismiss: ((WatermarkSettings?) -> Void)?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSegmentedControl()
        setupCollectionView()
        updateFontMenu()
        setupTextField()
        setupOpacitySliders()
        setupGestures()
        loadInitialSettings()
        updateUI()
    }
    
    // MARK: - Setup Methods
    
    private func configureSegmentedControl() {
        viewController.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        viewController.setTitleTextAttributes([.foregroundColor: UIColor(named: "Slider Text") ?? .gray], for: .normal)
        viewController.addTarget(self, action: #selector(viewControllerChanged(_:)), for: .valueChanged)
    }
    
    private func setupCollectionView() {
        colorsCollectonView.register(ColorsCollectionViewCell.nib(), forCellWithReuseIdentifier: ColorsCollectionViewCell.Identifier)
        colorsCollectonView.delegate = self
        colorsCollectonView.dataSource = self
        colorsCollectonView.allowsMultipleSelection = false
    }
    
    private func setupTextField() {
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemBackground.cgColor
        textField.clipsToBounds = true
        textField.delegate = self
        fontButton.isUserInteractionEnabled = true
    }
    
    private func setupOpacitySliders() {
        opacitySlider.minimumValue = 0
        opacitySlider.maximumValue = 100
        opacitySlider.addTarget(self, action: #selector(textOpacityChanged(_:)), for: .valueChanged)
        
        imageOpacitySlider.minimumValue = 0
        imageOpacitySlider.maximumValue = 100
        imageOpacitySlider.addTarget(self, action: #selector(imageOpacityChanged(_:)), for: .valueChanged)
    }
    
    private func setupGestures() {
        closeButton.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        uploadImageButton.addTapGestureRecognizer(target: self, action: #selector(uploadImageTapped))
        selectedImageCancelButton.addTapGestureRecognizer(target: self, action: #selector(cancelImageTapped))
        dismissContainer.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        saveButton.addTapGestureRecognizer(target: self, action: #selector(saveButtonTap))
    }
    
    private func loadInitialSettings() {
        let defaultTextOpacity: Float = 100
        let defaultImageOpacity: Float = 100
        
        viewController.selectedSegmentIndex = modifiedSettings?.textMode ?? false ? 0 : (modifiedSettings?.imageMode ?? false ? 1 : 0)
        
        textField.text = modifiedSettings?.textField ?? ""
        
        opacitySlider.value = modifiedSettings?.textOpacity ?? defaultTextOpacity
        updateOpacityLabel()
        
        if modifiedSettings == nil {
            fontLabel.text = selectedFont.fontName
        } else if let fontName = modifiedSettings?.textFont {
            if let font = Fonts.first(where: { $0.fontName == fontName }) {
                selectedFont = font
                fontLabel.text = font.fontName
            }
        }
        
        if let textColor = modifiedSettings?.textColor {
            selectedColor = textColor
            if let index = colors.firstIndex(where: { $0.color == textColor }) {
                colorsCollectonView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
            } else {
                colorsCollectonView.selectItem(at: IndexPath(item: colors.count, section: 0), animated: false, scrollPosition: [])
            }
        } else if !colors.isEmpty {
            selectedColor = colors[0].color
            colorsCollectonView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])
        }
        
        if modifiedSettings == nil && !colors.isEmpty {
            modifiedSettings = WatermarkSettings(
                textMode: !(textField.text?.isEmpty ?? true),
                imageMode: selectedImageView.image != nil,
                textField: textField.text,
                textOpacity: opacitySlider.value,
                textFont: selectedFont.fontName,
                textColor: selectedColor,
                image: selectedImageView.image,
                imageOpacity: defaultImageOpacity
            )
        }
        
        selectedImageView.image = modifiedSettings?.image
        
        imageOpacitySlider.value = modifiedSettings?.imageOpacity ?? defaultImageOpacity
        updateImageOpacityLabel()
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI() {
        updateContainerVisibility()
        updateImageVisibility()
        updateTextControlsAvailability()
        updateImageControlsAvailability()
    }
    
    private func updateOpacityLabel() {
        opacityLabel.text = String(format: "%.0f%%", opacitySlider.value)
    }
    
    private func updateImageOpacityLabel() {
        imageOpacityLabel.text = String(format: "%.0f%%", imageOpacitySlider.value)
    }
    
    private func updateContainerVisibility() {
        textContainer.isHidden = viewController.selectedSegmentIndex != 0
        imageContainer.isHidden = viewController.selectedSegmentIndex != 1
    }
    
    private func updateImageVisibility() {
        let hasImage = selectedImageView.image != nil
        selectedImageContainer.isHidden = !hasImage
        uploadImageButton.isHidden = hasImage
    }
    
    private func updateTextControlsAvailability() {
        let hasText = !(textField.text?.isEmpty ?? true)
        opacitySlider.isEnabled = hasText
        fontButton.isUserInteractionEnabled = hasText
        colorsCollectonView.isUserInteractionEnabled = hasText
        
        opacitySlider.alpha = hasText ? 1.0 : 0.5
        opacityLabel.alpha = hasText ? 1.0 : 0.5
        fontButton.alpha = hasText ? 1.0 : 0.5
        colorsCollectonView.alpha = hasText ? 1.0 : 0.5
    }
    
    private func updateImageControlsAvailability() {
        let hasImage = selectedImageView.image != nil
        imageOpacitySlider.isEnabled = hasImage
        imageOpacityLabel.alpha = hasImage ? 1.0 : 0.5
        imageOpacitySlider.alpha = hasImage ? 1.0 : 0.5
    }
    
    private func updateFontMenu() {
        let actions = Fonts.map { font in
            UIAction(title: font.fontName, state: (font.fontName == selectedFont.fontName) ? .on : .off) { [weak self] _ in
                self?.selectFont(font)
            }
        }
        let menu = UIMenu(title: "Fonts", children: actions)
        fontButton.showsMenuAsPrimaryAction = true
        fontButton.menu = menu
    }
    
    // MARK: - Settings Management
    
    private func createModifiedSettings() {
        modifiedSettings = WatermarkSettings(
            textMode: !(textField.text?.isEmpty ?? true),
            imageMode: selectedImageView.image != nil,
            textField: textField.text,
            textOpacity: opacitySlider.value,
            textFont: selectedFont.fontName,
            textColor: selectedColor,
            image: selectedImageView.image,
            imageOpacity: imageOpacitySlider.value
        )
    }
    
    private func selectFont(_ font: Font) {
        if modifiedSettings == nil {
            createModifiedSettings()
        }
        selectedFont = font
        fontLabel.text = font.fontName
        modifiedSettings?.textFont = font.fontName
        modifiedSettings?.textMode = true
        delegate?.textSettingsChanged(opacity: opacitySlider.value, font: selectedFont.fontName, color: selectedColor)
        updateContainerVisibility()
        updateFontMenu()
    }
}

// MARK: - UITextFieldDelegate
extension WatermarkSettingsViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if modifiedSettings == nil {
            createModifiedSettings()
        }
        delegate?.textFieldDidChange(textField.text)
        modifiedSettings?.textField = textField.text
        modifiedSettings?.textMode = !(textField.text?.isEmpty ?? true)
        updateTextControlsAvailability()
        updateContainerVisibility()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension WatermarkSettingsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == colorsCollectonView {
            return colors.count + 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorsCollectionViewCell.Identifier, for: indexPath) as! ColorsCollectionViewCell
        if indexPath.item == colors.count {
            cell.lastCell()
        } else {
            cell.configure(with: colors[indexPath.item].color)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == colorsCollectonView {
            if indexPath.item == colors.count {
                let colorPicker = UIColorPickerViewController()
                colorPicker.delegate = self
                colorPicker.selectedColor = selectedColor ?? .black
                if let sheet = colorPicker.sheetPresentationController {
                    let customDetent = UISheetPresentationController.Detent.custom { context in
                        context.maximumDetentValue * 0.8
                    }
                    sheet.detents = [customDetent, .large()]
                    sheet.selectedDetentIdentifier = customDetent.identifier
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                }
                colorPicker.modalPresentationStyle = .automatic
                present(colorPicker, animated: true, completion: nil)
            } else {
                if modifiedSettings == nil {
                    createModifiedSettings()
                }
                selectedColor = colors[indexPath.item].color
                modifiedSettings?.textColor = selectedColor
                modifiedSettings?.textMode = true
                delegate?.textSettingsChanged(opacity: opacitySlider.value, font: selectedFont.fontName, color: selectedColor)
                updateContainerVisibility()
            }
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension WatermarkSettingsViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        if modifiedSettings == nil {
            createModifiedSettings()
        }
        selectedColor = viewController.selectedColor
        modifiedSettings?.textColor = selectedColor
        modifiedSettings?.textMode = true
        colorsCollectonView.selectItem(at: IndexPath(item: colors.count, section: 0), animated: false, scrollPosition: [])
        self.delegate?.textSettingsChanged(opacity: self.opacitySlider.value, font: self.selectedFont.fontName, color: self.selectedColor)
        updateContainerVisibility()
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension WatermarkSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            if modifiedSettings == nil {
                createModifiedSettings()
            }
            selectedImageView.image = image
            modifiedSettings?.image = image
            modifiedSettings?.imageMode = true
            updateImageVisibility()
            updateImageControlsAvailability()
            updateContainerVisibility()
        }
        dismiss(animated: true) {
            self.delegate?.selectedImageChanged(self.selectedImageView.image)
        }
    }
}

// MARK: - @objc Methods
extension WatermarkSettingsViewController {
    @objc func textOpacityChanged(_ sender: UISlider) {
        if modifiedSettings == nil {
            createModifiedSettings()
        }
        delegate?.textSettingsChanged(opacity: sender.value, font: selectedFont.fontName, color: selectedColor)
        modifiedSettings?.textOpacity = sender.value
        modifiedSettings?.textMode = true
        updateOpacityLabel()
        updateContainerVisibility()
    }
    
    @objc func imageOpacityChanged(_ sender: UISlider) {
        if modifiedSettings == nil {
            createModifiedSettings()
        }
        delegate?.imageSettingsChanged(opacity: sender.value)
        modifiedSettings?.imageOpacity = sender.value
        modifiedSettings?.imageMode = true
        updateImageOpacityLabel()
        updateContainerVisibility()
    }
    
    @objc func viewControllerChanged(_ sender: UISegmentedControl) {
        updateContainerVisibility()
        updateTextControlsAvailability()
        updateImageControlsAvailability()
    }
    
    @objc func closeButtonTap() {
        dismiss(animated: true)
    }
    
    @objc func saveButtonTap() {
        if (textField.text == nil || textField.text!.isEmpty) && (selectedImageView.image == nil) {
            modifiedSettings = nil
        }
        
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?(self?.modifiedSettings)
        }
    }
    
    @objc func uploadImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc func cancelImageTapped() {
        selectedImageView.image = nil
        if modifiedSettings != nil {
            modifiedSettings?.image = nil
            modifiedSettings?.imageMode = false
            updateImageVisibility()
            updateImageControlsAvailability()
            updateContainerVisibility()
        }
        delegate?.selectedImageChanged(selectedImageView.image)
    }
}
