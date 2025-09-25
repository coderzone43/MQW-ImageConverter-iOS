import UIKit

struct RotateSettings {
    var straighten: Float?
    var flipHorizontal: Bool = false
    var flipVertical: Bool = false
}

protocol RotateSettingsViewControllerDelegate: AnyObject {
    func didUpdateRotation(_ sender: RotateSettingsViewController, settings: RotateSettings)
}

class RotateSettingsViewController: UIViewController {
    
    @IBOutlet weak var dismissContainer: UIView!
    @IBOutlet weak var rotateAspectsCollectionView: UICollectionView!
    @IBOutlet weak var straightenSlider: UISlider!
    @IBOutlet weak var straightenLabel: UILabel!
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var saveButton: UIView!
    
    var settings: RotateSettings?
    weak var delegate: RotateSettingsViewControllerDelegate?
    var onDismiss: ((RotateSettings?) -> Void)?
    
    var rotationAngle: CGFloat = 0
    var flipHorizontal: Bool = false
    var flipVertical: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSlider()
        setupCollectionView()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        straightenSlider.value = settings?.straighten ?? 0
        updateStraightenLabel()
    }

    // MARK: - Setup
    private func setupSlider() {
        straightenSlider.minimumValue = 0
        straightenSlider.maximumValue = 360
        straightenSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }

    private func setupCollectionView() {
        rotateAspectsCollectionView.register(AspectsCollectionViewCell.nib(),
                                             forCellWithReuseIdentifier: AspectsCollectionViewCell.Identifier)
        rotateAspectsCollectionView.delegate = self
        rotateAspectsCollectionView.dataSource = self
    }

    private func setupGestures() {
        closeButton.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        dismissContainer.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        saveButton.addTapGestureRecognizer(target: self, action: #selector(saveButtonTap))
    }

    private func updateStraightenLabel() {
        let value = straightenSlider.value
        straightenLabel.text = "\(Int(value))°"
    }
}

//MARK: - UICollectionViewDelegate/UICollectionViewDataSource
extension RotateSettingsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rotateAspects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AspectsCollectionViewCell.Identifier, for: indexPath) as! AspectsCollectionViewCell
        let aspect = rotateAspects[indexPath.item]
        cell.configure(with: aspect)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if settings == nil {
            settings = RotateSettings(straighten: straightenSlider.value)
        }
        
        switch indexPath.item {
        case 0:
            let current = Int(settings?.straighten ?? 0)
            let newValue: Float = {
                switch current % 360 {
                case 0: return 90
                case 90: return 180
                case 180: return 270
                default: return 0
                }
            }()
            settings?.straighten = newValue
            straightenSlider.value = newValue
            updateStraightenLabel()
        case 1:
            settings?.flipHorizontal.toggle()
        case 2:
            settings?.flipVertical.toggle()
        default:
            break
        }
        
        delegate?.didUpdateRotation(self, settings: settings!)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RotateSettingsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 14) / 3
        return CGSize(width: width, height: 62)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }
}

//MARK: - @objc Methods
extension RotateSettingsViewController {
    @objc private func sliderValueChanged(_ slider: UISlider) {
        let value = round(slider.value)
        if settings == nil {
            settings = RotateSettings(straighten: value)
        } else {
            settings?.straighten = value
        }

        updateStraightenLabel()
        delegate?.didUpdateRotation(self, settings: settings!)
    }

    @objc private func closeButtonTap() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTap() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?(self?.settings)
        }
    }
}
