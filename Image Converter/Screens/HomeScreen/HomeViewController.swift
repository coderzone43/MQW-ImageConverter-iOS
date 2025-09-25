import UIKit

class HomeViewController: BaseVC {
    
    @IBOutlet weak var toolsCollectionView: UICollectionView!
    @IBOutlet weak var customNavbar: CustomNavbar!
    @IBOutlet weak var customSearchBar: UITextField!
    @IBOutlet weak var discountButton: UIImageView!
    @IBOutlet weak var discountButtonBottomConstraint: NSLayoutConstraint!
    
    private var toolManager = ToolManager()
    private var sections: [(type: ToolType, items: [Tool])] = []
    private var filteredSections: [(type: ToolType, items: [Tool])] = []
    
    // MARK: - Fixed section order
    private let sectionOrder: [ToolType] = [.jpg, .png, .pdf, .other]
    
    private func sortedSections(_ secs: [(type: ToolType, items: [Tool])] ) -> [(type: ToolType, items: [Tool])] {
        let index = Dictionary(uniqueKeysWithValues: sectionOrder.enumerated().map { ($1, $0) })
        return secs.sorted { (lhs, rhs) in
            (index[lhs.type] ?? Int.max) < (index[rhs.type] ?? Int.max)
        }
    }
    
    func setupGestures() {
        discountButton.addTapGestureRecognizer(target: self, action: #selector(discountButtonTap))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customNavbar.screenTitle.text = "Image Converter"
        customNavbar.delegate = self
        
        sections = toolManager.toolsByCategory.map { (type, items) in
            (type: type, items: items)
        }
        sections = sortedSections(sections)
        filteredSections = sections
        
        if isIOS26() {
            discountButtonBottomConstraint.constant = 125
        } else {
            discountButtonBottomConstraint.constant = 30
        }
        
        setupGestures()
        configureCollectionView()
        configureSearchBar()
        offerDisplay()
        Utility.showPaywallScreen(caller: self)
    }
    
    override func checkProStatus() {
        discountButton.isHidden = AppDefaults.shared.isPremium
    }
    
    private func configureCollectionView() {
        toolsCollectionView.register(ToolCollectionViewCell.nib(), forCellWithReuseIdentifier: ToolCollectionViewCell.Identifier)
        
        toolsCollectionView.register(
            ToolSectionHeaderView.nib(),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ToolSectionHeaderView.Identifier
        )
        
        toolsCollectionView.dataSource = self
        toolsCollectionView.delegate = self
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 32)
        toolsCollectionView.collectionViewLayout = layout
    }
    
    private func configureSearchBar() {
        customSearchBar.layer.cornerRadius = 10
        customSearchBar.layer.borderWidth = 1
        customSearchBar.layer.borderColor = UIColor.systemBackground.cgColor
        customSearchBar.clipsToBounds = true
        customSearchBar.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
    }
    
    func offerDisplay() {
        discountButton.isHidden = AppDefaults.shared.isPremium
    }
    
    private func filterResults(searchText: String) {
        if searchText.isEmpty {
            filteredSections = sections
        } else {
            let filtered = sections.compactMap { section -> (type: ToolType, items: [Tool])? in
                let filteredItems = section.items.filter { tool in
                    tool.title.lowercased().contains(searchText)
                }
                return filteredItems.isEmpty ? nil : (section.type, filteredItems)
            }
            filteredSections = sortedSections(filtered)
        }
        toolsCollectionView.reloadData()
    }
}

// MARK: - UICollectionView
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        filteredSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredSections[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ToolCollectionViewCell.Identifier,
            for: indexPath
        ) as? ToolCollectionViewCell else { return UICollectionViewCell() }
        
        let tool = filteredSections[indexPath.section].items[indexPath.item]
        cell.configure(with: tool.image, name: tool.title)
        cell.layer.masksToBounds = false
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.05
        cell.layer.shadowOffset = CGSize(width: 2, height: 2)
        cell.layer.shadowRadius = 15
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ToolSectionHeaderView.Identifier,
            for: indexPath
        ) as? ToolSectionHeaderView else { return UICollectionViewCell() }
        
        header.sectionLabel.text = filteredSections[indexPath.section].type.rawValue
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tool = filteredSections[indexPath.section].items[indexPath.item]
        
        if AppDefaults.shared.canSendQuery {
            if let navigationController = self.navigationController {
                guard let uploadVC = storyboard?.instantiateViewController(withIdentifier: "UploadViewController") as? UploadViewController else { return }
                uploadVC.tool = tool
                navigationController.pushViewController(uploadVC, animated: true)
            }
        } else {
            Utility.showPaywallScreen(caller: self)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let layout = (collectionViewLayout as! UICollectionViewFlowLayout)
        let sectionInsets = layout.sectionInset
        let interItem = layout.minimumInteritemSpacing
        
        guard width > 0 else {
            return CGSize(width: 0, height: 130)
        }
        
        let columns: CGFloat = width > 700 ? 3 : 2
        let totalSpacing = sectionInsets.left + sectionInsets.right + interItem * (columns - 1)
        var itemWidth = (width - totalSpacing) / columns
        
        if itemWidth.isNaN || itemWidth <= 0 {
            itemWidth = 100
        }
        
        return CGSize(width: itemWidth, height: 130)
    }
}

// MARK: - CustomNavbarDelegate
extension HomeViewController: CustomNavbarDelegate {
    func didTapProButton() {
        Utility.showPaywallScreen(caller: self)
    }
}

//MARK: - @objc Methods
extension HomeViewController {
    @objc func discountButtonTap() {
        guard let proVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProViewController") as? ProViewController else { return }
        proVC.modalPresentationStyle = .fullScreen
        present(proVC, animated: true)
    }
    
    @objc private func searchTextChanged(_ textField: UITextField) {
        let searchText = textField.text?.lowercased() ?? ""
        filterResults(searchText: searchText)
    }
}
