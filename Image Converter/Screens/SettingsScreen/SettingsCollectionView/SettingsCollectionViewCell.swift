import UIKit

protocol SettingsCollectionViewCellDelegate: AnyObject {
    func menuItemSelected()
}

class SettingsCollectionViewCell: UICollectionViewCell {

    static let Identifier = "SettingsCollectionViewCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelView: UILabel!
    @IBOutlet weak var contextMenu: UIView!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var selectedItem: UILabel!
    @IBOutlet weak var languageMenuBtn: UIButton!
    
    var userDefaultValue: String?
    private var menuItems: [Any] = []
    weak var delegate: SettingsCollectionViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        contextMenu.isHidden = true
    }
    
    public func configure(with setting: Setting) {
        imageView.image = setting.icon
        labelView.text = setting.title
        
        if let menuItems = setting.contextMenuItems {
            self.menuItems = menuItems
            loadUserDefaults(for: setting.title)
            contextMenu.isHidden = false
            arrowImageView.isHidden = true
            
            if setting.title == "App Language", let language = getLanguageName(from: userDefaultValue) {
                selectedItem.text = language
            } else {
                selectedItem.text = userDefaultValue
            }

            setupContextMenu(for: setting.title)
        } else {
            contextMenu.isHidden = true
            arrowImageView.isHidden = false
            selectedItem.text = nil
        }
    }

    private func setupContextMenu(for settingTitle: String) {
        if settingTitle == "App Language" {
            let languageActions: [UIAction] = menuItems.compactMap { language in
                guard let language = language as? Languages else { return nil }
                return UIAction(
                    title: language.languageName,
                    state: (language.code == userDefaultValue) ? .on : .off,
                    handler: { [weak self] _ in
                        self?.updateContextMenuSelection(with: language, type: .language)
                    }
                )
            }
            let languageMenu = UIMenu(title: "Languages", options: .displayInline, children: languageActions)
            languageMenuBtn.menu = languageMenu
            languageMenuBtn.showsMenuAsPrimaryAction = true
        } else if settingTitle == "Display Mode" {
            let displayActions: [UIAction] = menuItems.compactMap { mode in
                guard let mode = mode as? String else { return nil }
                return UIAction(
                    title: mode,
                    state: (mode == userDefaultValue) ? .on : .off,
                    handler: { [weak self] _ in
                        self?.updateContextMenuSelection(with: mode, type: .displayMode)
                    }
                )
            }
            let displayMenu = UIMenu(title: "Display Mode", options: .displayInline, children: displayActions)
            languageMenuBtn.menu = displayMenu
            languageMenuBtn.showsMenuAsPrimaryAction = true
        }
    }

    func loadUserDefaults(for settingTitle: String) {
        if settingTitle == "App Language" {
            userDefaultValue = AppDefaults.shared.appLanguage
        } else if settingTitle == "Display Mode" {
            userDefaultValue = AppDefaults.shared.displayMode
        }
    }

    private func getLanguageName(from code: String?) -> String? {
        guard let code = code else { return nil }
        return menuItems.compactMap { item in
            if let language = item as? Languages, language.code == code {
                return language.languageName
            }
            return nil
        }.first
    }

    private func updateContextMenuSelection(with item: Any, type: SettingType) {
        if type == .language {
            if let item = item as? Languages {
                selectedItem.text = item.languageName
                userDefaultValue = item.code
                AppDefaults.shared.appLanguage = item.code
            }
        } else if type == .displayMode {
            if let item = item as? String {
                selectedItem.text = item
                userDefaultValue = item
                App.appearance = .init(rawValue: item)!
            }
        }
        delegate?.menuItemSelected()
    }

    static func nib() -> UINib {
        UINib(nibName: Identifier, bundle: nil)
    }
}

enum SettingType {
    case language
    case displayMode
}
