import UIKit
import PhotosUI
import MobileCoreServices
import UniformTypeIdentifiers

protocol DraggableViewDelegate: AnyObject {
    func didReceiveFileURLs(fileURL: URL) -> Void
}

class DraggableView: CustomGradientBorderView, UINavigationControllerDelegate {
    // MARK: - Outlets
    @IBOutlet weak var uploadBtn: UIButton!
    
    // MARK: - Variables
    weak var delegate: DraggableViewDelegate?
    weak var viewController: UIViewController?
    var tool: Tool?
    private var contentView: UIView!
    private var supportedTypes: [UTType] = []
    var customPicker: CustomPicker?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // MARK: - Load View
    private func commonInit() {
        let bundle = Bundle(for: type(of: self))
        let nibName = "DraggableView"
        guard let view = bundle.loadNibNamed(nibName, owner: self, options: nil)?.first as? UIView else {
            print("Could not load nib: \(nibName)")
            return
        }
        
        contentView = view
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        isUserInteractionEnabled = true
        uploadBtn.addTapGestureRecognizer(target: self, action: #selector(showActionSheet))
        addInteraction(UIDropInteraction(delegate: self))
    }
}

//MARK: - CustomPickerDelegate
extension DraggableView: CustomPickerDelegate {
    func didReceiveFileURLs(urls: [URL]) {
        guard let url = urls.first else { return }
        delegate?.didReceiveFileURLs(fileURL: url)
    }
}

//MARK: - UIDropInteractionDelegate
extension DraggableView: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            self.contentView.backgroundColor = self.contentView.backgroundColor?.withAlphaComponent(0.8)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = CGAffineTransform.identity
            self.contentView.backgroundColor = self.contentView.backgroundColor?.withAlphaComponent(1.0)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let tool, let itemProvider = session.items.first?.itemProvider else { return }
        
        if isSupportedFileType(itemProvider) {
            let fileExtension = extractFileExtension(itemProvider)
            
            itemProvider.loadDataRepresentation(forTypeIdentifier: itemProvider.registeredTypeIdentifiers.first ?? "") { [weak self] data, error in
                guard let data = data else { return }
                
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = "Temp-\(UUID().uuidString).\(tool.fromFormat != .img ? tool.fromFormat.rawValue.lowercased() : fileExtension)"
                let fileURL = tempDirectory.appendingPathComponent(fileName)
                do {
                    try data.write(to: fileURL)
                    self?.delegate?.didReceiveFileURLs(fileURL: fileURL)
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        } else {
            showAlertForUnsupportedFileType()
        }
    }

    // MARK: Helper Methods
    private func isSupportedFileType(_ itemProvider: NSItemProvider) -> Bool {
        supportedTypes = Utility.fetchAllowedFileTypes(with: tool)
        
        for type in supportedTypes {
            if itemProvider.hasItemConformingToTypeIdentifier(type.identifier) {
                return true
            }
        }
        return false
    }
    
    private func extractFileExtension(_ itemProvider: NSItemProvider) -> String {
        let supportedTypes = Utility.fetchAllowedFileTypes(with: tool)
        
        for type in supportedTypes {
            if itemProvider.hasItemConformingToTypeIdentifier(type.identifier) {
                let identifier = type.identifier
                if let lastDotIndex = identifier.lastIndex(of: ".") {
                    let extensionSubstring = identifier[lastDotIndex...].dropFirst()
                    return String(extensionSubstring)
                }
            }
        }
        return ""
    }
    
    private func showAlertForUnsupportedFileType() {
        let alert = UIAlertController(title: "Invalid File Type", message: "The file type is not supported. Please upload a valid file.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController?.present(alert, animated: true, completion: nil)
    }
}

//MARK: - @objc Methods
extension DraggableView {
    @objc private func showActionSheet() {
        guard let viewController = viewController else { return }
        customPicker = CustomPicker(viewController: viewController, tool: tool)
        customPicker?.delegate = self
        customPicker?.showActionSheet()
    }
}
