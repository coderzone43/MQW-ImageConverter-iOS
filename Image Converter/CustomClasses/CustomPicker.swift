import UIKit
import PhotosUI
import UniformTypeIdentifiers

protocol CustomPickerDelegate: AnyObject {
    func didReceiveFileURLs(urls: [URL]) -> Void
}

class CustomPicker: NSObject {
    var viewController: UIViewController?
    let tool: Tool?
    var allowMultiSelection: Bool = false
    private var supportedTypes: [UTType] = []
    weak var delegate: CustomPickerDelegate?
    
    init(viewController: UIViewController, tool: Tool?) {
        self.viewController = viewController
        self.tool = tool
        self.supportedTypes = Utility.fetchAllowedFileTypes(with: tool)
    }
    
    func showActionSheet() {
        if tool?.type == .pdfToImage {
            openFilePicker()
        } else {
            let actionSheet = UIAlertController(title: "Select File", message: "Choose an option to upload", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Photo Gallery", style: .default, handler: { [weak self] _ in
                self?.openPhotoGallery()
            }))
            actionSheet.addAction(UIAlertAction(title: "Document", style: .default, handler: { [weak self] _ in
                self?.openFilePicker()
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            if Constants.currentDevice.model == "iPad" {
                if let popoverController = actionSheet.popoverPresentationController {
                    popoverController.sourceView = viewController?.view
                    popoverController.sourceRect = CGRect(x: viewController!.view.bounds.midX, y: viewController!.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
            }

            viewController?.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func openPhotoGallery() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController?.present(picker, animated: true, completion: nil)
    }
    
    func openFilePicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = allowMultiSelection
        viewController?.present(picker, animated: true, completion: nil)
    }
    
    private func isSupportedFileType(_ fileExtension: String) -> Bool {
        for type in supportedTypes {
            if let utTypeExtension = type.preferredFilenameExtension, utTypeExtension.lowercased() == fileExtension.lowercased() {
                return true
            }
        }
        return false
    }
    
    private func showAlertForUnsupportedFileType() {
        let alert = UIAlertController(title: "Invalid File Type", message: "The file type is not supported. Please upload a valid file.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController?.present(alert, animated: true, completion: nil)
    }
}

//MARK: - PHPickerViewControllerDelegate
extension CustomPicker: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let tool, let selectedItem = results.first else { return }
        
        selectedItem.itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] (url, error) in
            guard let self, let fileURL = url as? URL else { return }
            let fileExtension = fileURL.pathExtension.lowercased()
            
            if self.isSupportedFileType(fileExtension) {
                
                selectedItem.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] (data, error) in
                    guard let self = self, let data = data else {
                        print("Error loading data: \(String(describing: error))")
                        return
                    }
                    
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let fileName = "Temp-\(UUID().uuidString).\(tool.fromFormat != .img ? tool.fromFormat.rawValue.lowercased() : fileExtension)"
                    let newFileURL = tempDirectory.appendingPathComponent(fileName)
                    
                    FileManager.default.createFile(atPath: newFileURL.path, contents: data, attributes: nil)
                    print("File saved successfully at: \(newFileURL)")
                    self.delegate?.didReceiveFileURLs(urls: [newFileURL])
                    
                }
            } else {
                DispatchQueue.main.async {
                    self.viewController?.dismiss(animated: true) {
                        self.showAlertForUnsupportedFileType()
                    }
                }
            }
        }
    }
}

//MARK: - UIDocumentPickerDelegate
extension CustomPicker: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let tool else { return }
        var selectedFileURLs: [URL] = []
        for url in urls {
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = "Temp-\(UUID().uuidString).\(tool.fromFormat != .img ? tool.fromFormat.rawValue.lowercased() : url.pathExtension)"
            let newFileURL = tempDirectory.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.copyItem(at: url, to: newFileURL)
                print("File saved successfully at: \(newFileURL)")
                selectedFileURLs.append(newFileURL)
            } catch {
                print("Error saving file: \(error)")
            }
        }
        delegate?.didReceiveFileURLs(urls: selectedFileURLs)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}
