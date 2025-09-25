import UIKit

class ToolsViewController: UIViewController {

    @IBOutlet weak var toolsCollectionView: UICollectionView!
    @IBOutlet weak var customSearchBar: UITextField!
    @IBOutlet weak var customNavbar: CustomNavbar!
    
    private var toolManager = ToolManager()
    private var tools: [Tool] = []
    private var filteredTools: [Tool] = []
    
    private var tapGesture: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customNavbar.screenTitle.text = "Tools"
        customNavbar.delegate = self
        
        tools = toolManager.toolsByCategory[.other] ?? []
        filteredTools = tools
        
        configureCollectionView()
        configureSearchBar()
    }
    
    private func configureCollectionView() {
        toolsCollectionView.register(ToolCollectionViewCell.nib(), forCellWithReuseIdentifier: ToolCollectionViewCell.Identifier)
        
        toolsCollectionView.register(ToolSectionHeaderView.nib(),
                                     forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                     withReuseIdentifier: ToolSectionHeaderView.Identifier)
        
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

    @objc private func searchTextChanged(_ textField: UITextField) {
        let searchText = textField.text?.lowercased() ?? ""
        filterResults(searchText: searchText)
    }
    
    private func filterResults(searchText: String) {
        if searchText.isEmpty {
            filteredTools = tools
        } else {
            filteredTools = tools.filter { tool in
                tool.title.lowercased().contains(searchText)
            }
        }
        toolsCollectionView.reloadData()
    }
}

extension ToolsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredTools.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ToolCollectionViewCell.Identifier,
            for: indexPath
        ) as! ToolCollectionViewCell
        
        let tool = filteredTools[indexPath.item]
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
        
        header.sectionLabel.text = "Tools"
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tool = filteredTools[indexPath.item]
        
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

extension ToolsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let sectionInsets = (collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
        let interItem = (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        
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

extension ToolsViewController: CustomNavbarDelegate {
    func didTapProButton() {
        guard let paywallVC = self.storyboard?.instantiateViewController(withIdentifier: "PaywallViewController") as? PaywallViewController else { return }
        paywallVC.modalPresentationStyle = .fullScreen
        present(paywallVC, animated: true)
    }
}
