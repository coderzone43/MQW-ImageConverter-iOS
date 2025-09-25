import UIKit
import PDFKit
import UniformTypeIdentifiers

class UploadViewController: UIViewController {
    
    @IBOutlet weak var customNavbar: SecondaryCustomNavbar!
    @IBOutlet weak var dragAndDropView: DraggableView!
    
    var tool: Tool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customNavbar.screenTitle.text = "Upload File"
        dragAndDropView.tool = tool
        dragAndDropView.viewController = self
        dragAndDropView.delegate = self
    }
    
    private func navigateToConversionVC(with fileURL: URL) {
        Task{ @MainActor in
            guard let navigationController = self.navigationController else { return }
            guard let conversionVC = storyboard?.instantiateViewController(withIdentifier: "ConversionViewController") as? ConversionViewController else { return }
            
            conversionVC.tool = tool
            conversionVC.files = [File(url: fileURL)]
            navigationController.pushViewController(conversionVC, animated: true)
            navigationController.viewControllers.removeAll { $0 == self }
        }
    }
}

extension UploadViewController: DraggableViewDelegate {
    func didReceiveFileURLs(fileURL: URL) {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            if let fileSize = fileAttributes[.size] as? Int64 {
                let maxSizeInBytes = Int64(100 * 1024 * 1024)
                
                if fileSize > maxSizeInBytes {
                    let alert = UIAlertController(
                        title: "File Too Large",
                        message: "The selected file is larger than 100MB. Please choose a smaller file.",
                        preferredStyle: .alert
                    )
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                }
            }
            
            if let isImmutable = fileAttributes[.immutable] as? Bool, isImmutable {
                let alert = UIAlertController(
                    title: "File Locked",
                    message: "The selected file is locked in the file system. Please unlock the file or choose a different file.",
                    preferredStyle: .alert
                )
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
            }
            
            if fileURL.pathExtension.lowercased() == "pdf" {
                if let pdfDocument = PDFDocument(url: fileURL) {
                    if pdfDocument.isLocked {
                        let alert = UIAlertController(
                            title: "File Locked",
                            message: "The selected file is password-protected. Please unlock the file or choose a different file.",
                            preferredStyle: .alert
                        )
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            return
                        }
                    }
                } else {
                    let alert = UIAlertController(
                        title: "Invalid File",
                        message: "The selected file is not a valid file. Please choose a different file.",
                        preferredStyle: .alert
                    )
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                }
            }
            
            navigateToConversionVC(with: fileURL)
        } catch {
            let alert = UIAlertController(
                title: "Error",
                message: "Unable to access file: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
