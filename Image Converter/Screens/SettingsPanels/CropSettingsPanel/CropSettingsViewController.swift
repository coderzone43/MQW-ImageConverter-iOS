import UIKit

class CropSettingsViewController: UIViewController {

    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var aspectsCollectionView: UICollectionView!
    @IBOutlet weak var dismissContainer: UIView!
    @IBOutlet weak var saveButton: UIView!
    
    var defaultIndexPath = IndexPath(item: 0, section: 0)
    var lastSelectedIndexPath: IndexPath?
    var onDismiss: ((IndexPath?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastSelectedIndexPath == nil {
            lastSelectedIndexPath = defaultIndexPath
        }
        let indexPathToSelect = lastSelectedIndexPath ?? defaultIndexPath
        aspectsCollectionView.selectItem(at: indexPathToSelect, animated: false, scrollPosition: .centeredHorizontally)
        if let cell = aspectsCollectionView.cellForItem(at: indexPathToSelect) as? AspectsCollectionViewCell {
            configureCell(cell, isSelected: true)
        }
    }
    
    func setupCollectionView() {
        aspectsCollectionView.register(AspectsCollectionViewCell.nib(), forCellWithReuseIdentifier: AspectsCollectionViewCell.Identifier)
        aspectsCollectionView.delegate = self
        aspectsCollectionView.dataSource = self
    }
    
    func setupGestures() {
        closeButton.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        dismissContainer.addTapGestureRecognizer(target: self, action: #selector(closeButtonTap))
        saveButton.addTapGestureRecognizer(target: self, action: #selector(saveButtonTap))
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        aspectsCollectionView.reloadData()
    }
    
    private func configureCell(_ cell: AspectsCollectionViewCell, isSelected: Bool) {
        if isSelected {
            cell.containerView.layer.borderColor = UIColor(named: "Primary")?.cgColor
            cell.containerView.backgroundColor = UIColor(named: "Upload Background")
            cell.labelView.textColor = UIColor(named: "Primary")
            cell.imageView.tintColor = UIColor(named: "Primary")
        } else {
            cell.containerView.layer.borderColor = UIColor(named: "Tabbar Border")?.cgColor
            cell.containerView.backgroundColor = UIColor.clear
            cell.labelView.textColor = UIColor.label
            cell.imageView.tintColor = UIColor.label
        }
    }
}

extension CropSettingsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cropAspects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AspectsCollectionViewCell.Identifier, for: indexPath) as! AspectsCollectionViewCell
        let aspect = cropAspects[indexPath.item]
        cell.configure(with: aspect)
        
        let isSelected = indexPath == (lastSelectedIndexPath ?? defaultIndexPath)
        configureCell(cell, isSelected: isSelected)
        
        return cell
    }
}

extension CropSettingsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 14 ) / 3
        return CGSize(width: width, height: 62)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
        collectionView.reloadData()
    }
}

//MARK: - @objc Methods

extension CropSettingsViewController {
    @objc func closeButtonTap() {
        dismiss(animated: true)
    }
    
    @objc func saveButtonTap() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?(self?.lastSelectedIndexPath)
        }
    }
}
