import UIKit

struct ResizeSettings {
    var inputMode: Int
    var preset: String?
    var presetOption: String?
    var width: Int
    var height: Int
    var aspectRatioCheck: Bool
    var sliderValue: Int
}

class ResizeSettingsViewController: UIViewController {
    
    @IBOutlet weak var dismissContainer: UIView!
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var viewControl: UISegmentedControl!
    @IBOutlet weak var widthTextbox: UITextField!
    @IBOutlet weak var heightTextbox: UITextField!
    @IBOutlet weak var aspectRatioCheckbox: Checkbox!
    @IBOutlet weak var presetButton: UIButton!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var typeContainer: UIView!
    @IBOutlet weak var sizeContainer: UIView!
    @IBOutlet weak var presetLabelView: UILabel!
    @IBOutlet weak var typeLabelView: UILabel!
    @IBOutlet weak var percentageContainer: UIView!
    @IBOutlet weak var percentageLabelView: UILabel!
    @IBOutlet weak var percentageSlider: UISlider!
    @IBOutlet weak var percentageConversionContainer: UIView!
    @IBOutlet weak var fromSizePercentage: UILabel!
    @IBOutlet weak var toSizePercentage: UILabel!
    @IBOutlet weak var saveButton: UIView!
    
    private var presetMenuBtn: UIButton!
    private var typeMenuBtn: UIButton!
    private var selectedPreset: Preset = Presets.first(where: { $0.name == "Custom" })!
    private var selectedOption: PresetOption?
    
    var originalSize: [Int]?
    var modifiedSize: ResizeSettings?
    var onDismiss: ((ResizeSettings?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        viewControl.setTitleTextAttributes([.foregroundColor: UIColor(named: "Slider Text")!], for: .normal)
        setupGestures()
        setupTextFields()
        
        percentageSlider.addTarget(self, action: #selector(percentageSliderChanged(_:)), for: .valueChanged)
        viewControl.addTarget(self, action: #selector(viewControlChanged(_:)), for: .valueChanged)
        aspectRatioCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let modifiedSize = modifiedSize {
            viewControl.selectedSegmentIndex = modifiedSize.inputMode
            
            if modifiedSize.inputMode == 0 {
                if let presetName = modifiedSize.preset,
                   let preset = Presets.first(where: { $0.name == presetName }) {
                    selectedPreset = preset
                    presetLabelView.text = presetName
                    if let optionName = modifiedSize.presetOption,
                       let option = preset.options?.first(where: { $0.name == optionName }) {
                        selectedOption = option
                        typeLabelView.text = optionName
                        typeContainer.isHidden = false
                    } else {
                        selectedOption = nil
                        typeContainer.isHidden = true
                    }
                } else {
                    selectedPreset = Presets.first(where: { $0.name == "Custom" })!
                    presetLabelView.text = selectedPreset.name
                    typeContainer.isHidden = true
                    selectedOption = nil
                }
                
                widthTextbox.text = modifiedSize.width > 0 ? "\(modifiedSize.width)" : ""
                heightTextbox.text = modifiedSize.height > 0 ? "\(modifiedSize.height)" : ""
                
                if aspectRatioCheckbox.checked != modifiedSize.aspectRatioCheck {
                    aspectRatioCheckbox.checked = modifiedSize.aspectRatioCheck
                }
                
                percentageSlider.minimumValue = 0
                percentageSlider.maximumValue = 100
                percentageSlider.value = Float(modifiedSize.sliderValue)
            } else {
                percentageSlider.minimumValue = 0
                percentageSlider.maximumValue = 100
                percentageSlider.value = Float(modifiedSize.sliderValue)
                
                if aspectRatioCheckbox.checked != modifiedSize.aspectRatioCheck {
                    aspectRatioCheckbox.checked = modifiedSize.aspectRatioCheck
                }
                
                selectedPreset = Presets.first(where: { $0.name == "Custom" })!
                presetLabelView.text = selectedPreset.name
                typeContainer.isHidden = true
                selectedOption = nil
                guard let size = Presets[0].size else { return }
                widthTextbox.text = "\(size[0])"
                heightTextbox.text = "\(size[1])"
            }
        } else {
            selectedPreset = Presets.first(where: { $0.name == "Custom" })!
            presetLabelView.text = selectedPreset.name
            typeContainer.isHidden = true
            selectedOption = nil
            
            if let size = selectedPreset.size, size.count >= 2 {
                widthTextbox.text = "\(size[0])"
                heightTextbox.text = "\(size[1])"
            } else {
                widthTextbox.text = ""
                heightTextbox.text = ""
            }
            
            if aspectRatioCheckbox.checked != false {
                aspectRatioCheckbox.checked = false
            }
            percentageSlider.minimumValue = 0
            percentageSlider.maximumValue = 100
            percentageSlider.value = 100
            viewControl.selectedSegmentIndex = 0
            modifiedSize = nil
        }
        
        updateContainerVisibility()
        updatePercentageLabels()
        updatePresetMenu()
        updateTypeMenu()
    }
    
    private func setupTextFields() {
        widthTextbox.layer.cornerRadius = 10
        widthTextbox.layer.borderWidth = 1
        widthTextbox.layer.borderColor = UIColor.systemBackground.cgColor
        widthTextbox.clipsToBounds = true
        
        heightTextbox.layer.cornerRadius = 10
        heightTextbox.layer.borderWidth = 1
        heightTextbox.layer.borderColor = UIColor.systemBackground.cgColor
        heightTextbox.clipsToBounds = true
        
        widthTextbox.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        heightTextbox.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func updatePresetMenu() {
        let actions = Presets.map { preset in
            UIAction(title: preset.name, state: (preset.name == selectedPreset.name) ? .on : .off) { [weak self] _ in
                self?.selectPreset(preset)
            }
        }
        let menu = UIMenu(title: "Presets", children: actions)
        presetButton.showsMenuAsPrimaryAction = true
        presetButton.menu = menu
    }
    
    private func selectPreset(_ preset: Preset) {
        selectedPreset = preset
        presetLabelView.text = preset.name
        
        let aspectRatioCheck = modifiedSize?.aspectRatioCheck ?? aspectRatioCheckbox.checked
        
        if let options = preset.options, !options.isEmpty {
            typeContainer.isHidden = false
            selectedOption = options.first
            typeLabelView.text = selectedOption?.name
            updateTypeMenu()
            if let size = selectedOption?.size, size.count >= 2 {
                widthTextbox.text = "\(size[0])"
                heightTextbox.text = "\(size[1])"
                modifiedSize = ResizeSettings(
                    inputMode: 0,
                    preset: preset.name,
                    presetOption: selectedOption?.name,
                    width: size[0],
                    height: size[1],
                    aspectRatioCheck: aspectRatioCheck,
                    sliderValue: 100
                )
            } else {
                widthTextbox.text = ""
                heightTextbox.text = ""
                modifiedSize = ResizeSettings(
                    inputMode: 0,
                    preset: preset.name,
                    presetOption: selectedOption?.name,
                    width: 0,
                    height: 0,
                    aspectRatioCheck: aspectRatioCheck,
                    sliderValue: 100
                )
            }
        } else {
            typeContainer.isHidden = true
            selectedOption = nil
            if let size = preset.size, size.count >= 2 {
                widthTextbox.text = "\(size[0])"
                heightTextbox.text = "\(size[1])"
                modifiedSize = ResizeSettings(
                    inputMode: 0,
                    preset: preset.name,
                    presetOption: nil,
                    width: size[0],
                    height: size[1],
                    aspectRatioCheck: aspectRatioCheck,
                    sliderValue: 100
                )
            } else {
                widthTextbox.text = ""
                heightTextbox.text = ""
                modifiedSize = ResizeSettings(
                    inputMode: 0,
                    preset: preset.name,
                    presetOption: nil,
                    width: 0,
                    height: 0,
                    aspectRatioCheck: aspectRatioCheck,
                    sliderValue: 100
                )
            }
        }
        
        viewControl.selectedSegmentIndex = 0
        updateContainerVisibility()
        updatePresetMenu()
    }
    
    private func updateTypeMenu() {
        guard let options = selectedPreset.options else {
            typeContainer.isHidden = true
            return
        }
        
        let actions = options.map { option in
            UIAction(title: option.name, state: (option.name == selectedOption?.name) ? .on : .off) { [weak self] _ in
                self?.selectOption(option)
            }
        }
        let menu = UIMenu(title: "Types", children: actions)
        typeButton.showsMenuAsPrimaryAction = true
        typeButton.menu = menu
    }
    
    private func selectOption(_ option: PresetOption) {
        selectedOption = option
        typeLabelView.text = option.name
        
        let aspectRatioCheck = modifiedSize?.aspectRatioCheck ?? aspectRatioCheckbox.checked
        
        if let size = option.size, size.count >= 2 {
            widthTextbox.text = "\(size[0])"
            heightTextbox.text = "\(size[1])"
            modifiedSize = ResizeSettings(
                inputMode: 0,
                preset: selectedPreset.name,
                presetOption: option.name,
                width: size[0],
                height: size[1],
                aspectRatioCheck: aspectRatioCheck,
                sliderValue: 100
            )
        } else {
            widthTextbox.text = ""
            heightTextbox.text = ""
            modifiedSize = ResizeSettings(
                inputMode: 0,
                preset: selectedPreset.name,
                presetOption: option.name,
                width: 0,
                height: 0,
                aspectRatioCheck: aspectRatioCheck,
                sliderValue: 100
            )
        }
        
        viewControl.selectedSegmentIndex = 0
        updateContainerVisibility()
        updateTypeMenu()
    }
    
    private func updateContainerVisibility() {
        sizeContainer.isHidden = viewControl.selectedSegmentIndex != 0
        percentageContainer.isHidden = viewControl.selectedSegmentIndex != 1
        updatePercentageLabels()
    }
    
    private func updatePercentageLabels() {
        percentageLabelView.text = "\(Int(percentageSlider.value))%"
        
        if let original = originalSize, original.count >= 2 {
            fromSizePercentage.text = "\(original[0])x\(original[1])"
            let percentage = Double(percentageSlider.value) / 100.0
            let newWidth = Int(Double(original[0]) * percentage)
            let newHeight = Int(Double(original[1]) * percentage)
            toSizePercentage.text = "\(newWidth)x\(newHeight)"
        } else {
            fromSizePercentage.text = ""
            toSizePercentage.text = ""
        }
    }
    
    func setupGestures() {
        closeButton.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        dismissContainer.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        saveButton.addTapGestureRecognizer(target: self, action: #selector(saveButtonTap))
    }
}

//MARK: - @objc Methods
extension ResizeSettingsViewController {
    @objc func textFieldDidChange(_ textField: UITextField) {
        if selectedPreset.name != "Custom" {
            selectPreset(Presets.first(where: { $0.name == "Custom" })!)
        }
        
        let aspectRatioCheck = modifiedSize?.aspectRatioCheck ?? aspectRatioCheckbox.checked
        
        if let widthText = widthTextbox.text, let heightText = heightTextbox.text,
           let width = Int(widthText), let height = Int(heightText) {
            modifiedSize = ResizeSettings(
                inputMode: 0,
                preset: nil,
                presetOption: nil,
                width: width,
                height: height,
                aspectRatioCheck: aspectRatioCheck,
                sliderValue: 100
            )
        } else {
            modifiedSize = nil
        }
        
        viewControl.selectedSegmentIndex = 0
        updateContainerVisibility()
    }
    
    @objc func percentageSliderChanged(_ sender: UISlider) {
        let percentage = Int(sender.value)
        percentageLabelView.text = "\(percentage)%"
        
        let aspectRatioCheck = modifiedSize?.aspectRatioCheck ?? aspectRatioCheckbox.checked
        
        if let original = originalSize, original.count >= 2 {
            let newWidth = Int(original[0] * Int(percentage) / 100)
            let newHeight = Int(original[1] * Int(percentage) / 100)
            guard let size = Presets[0].size else { return }
            modifiedSize = ResizeSettings(
                inputMode: 1,
                preset: nil,
                presetOption: nil,
                width: newWidth,
                height: newHeight,
                aspectRatioCheck: aspectRatioCheck,
                sliderValue: percentage
            )
        } else {
            modifiedSize = nil
            widthTextbox.text = ""
            heightTextbox.text = ""
        }
        
        updatePercentageLabels()
    }
    
    @objc func viewControlChanged(_ sender: UISegmentedControl) {
        updateContainerVisibility()
    }
    
    @objc func closeButtonTap() {
        dismiss(animated: true)
    }
    
    @objc func checkboxValueChanged(_ sender: Checkbox) {
        let currentWidth = Int(widthTextbox.text ?? "") ?? modifiedSize?.width ?? 0
        let currentHeight = Int(heightTextbox.text ?? "") ?? modifiedSize?.height ?? 0
        let currentInputMode = viewControl.selectedSegmentIndex
        let currentSliderValue = Int(percentageSlider.value)
        
        modifiedSize = ResizeSettings(
            inputMode: currentInputMode,
            preset: selectedPreset.name == "Custom" ? nil : selectedPreset.name,
            presetOption: selectedOption?.name,
            width: currentWidth,
            height: currentHeight,
            aspectRatioCheck: sender.checked,
            sliderValue: currentSliderValue
        )
    }
    
    @objc func saveButtonTap() {
        let currentWidth = Int(widthTextbox.text ?? "") ?? modifiedSize?.width ?? 0
        let currentHeight = Int(heightTextbox.text ?? "") ?? modifiedSize?.height ?? 0
        
        
        
        if currentWidth > 0 && currentHeight > 0 && currentWidth < 10000 && currentHeight < 10000 {
            
            if modifiedSize == nil || (widthTextbox.text?.isEmpty ?? true && heightTextbox.text?.isEmpty ?? true && percentageSlider.value == 100) {
                let currentInputMode = viewControl.selectedSegmentIndex
                
                let currentSliderValue = Int(percentageSlider.value)
                
                modifiedSize = ResizeSettings(
                    inputMode: currentInputMode,
                    preset: selectedPreset.name == "Custom" ? nil : selectedPreset.name,
                    presetOption: selectedOption?.name,
                    width: currentWidth,
                    height: currentHeight,
                    aspectRatioCheck: aspectRatioCheckbox.checked,
                    sliderValue: currentSliderValue
                )
            }
            
            dismiss(animated: true) { [weak self] in
                print(self?.modifiedSize)
                self?.onDismiss?(self?.modifiedSize)
            }
        } else {
            let alert = UIAlertController(title: "Invalid Values", message: "Width and height must be between 0 and 10,000.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
