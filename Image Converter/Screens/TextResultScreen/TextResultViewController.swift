import UIKit

class TextResultViewController: UIViewController {
    
    @IBOutlet weak var customNavbar: SecondaryCustomNavbar!
    @IBOutlet weak var resultTextLabel: UILabel!
    @IBOutlet weak var copyButton: UIView!
    @IBOutlet weak var downloadButton: UIView!
    
    var file: File = File(url: FileManager.default.temporaryDirectory)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customNavbar.screenTitle.text = "Extract Text"
        resultTextLabel.text = file.extractedText
        setupGestures()
    }
    
    func setupGestures() {
        copyButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(copyButtonTap)))
        downloadButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(downloadButtonTap)))
    }
    
    func saveHistory(with data: Data) {
        var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let date = Date()
        let id = UUID().uuidString
        let title = "IMG-to-TXT-\(id).txt"
        directory.appendPathComponent(title)
        
        do {
            try data.write(to: directory)
            print("History saved at \(directory)")
        } catch {
            print("Failed to save History.")
        }
        
        let history = History(
            id: id,
            toType: FileFormat.txt,
            category: ConversionCategory.imageToText,
            action: ConversionAction.extractText,
            title: title,
            size: data.count,
            date: date
        )
        
        do {
            _ = try HistoryRepository.shared.createNewHistory(with: history)
        } catch {
            print("Error occurred while saving history")
        }
    }
    
    func saveResultDocument(resultURL: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [resultURL], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
}

//MARK: - @objc Methods

extension TextResultViewController {
    @objc func copyButtonTap() {
        UIPasteboard.general.string = resultTextLabel.text
        guard let downloadedVC = storyboard?.instantiateViewController(withIdentifier: "DownloadedViewController") as? DownloadedViewController else { return }
        downloadedVC.changedText = "Text Copied!"
        downloadedVC.modalTransitionStyle = .crossDissolve
        downloadedVC.modalPresentationStyle = .overFullScreen
        present(downloadedVC, animated: true)
    }
    
    @objc func downloadButtonTap() {
        guard let url = file.resultURL else { return }
        saveResultDocument(resultURL: url)
    }
}

extension TextResultViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let url = self?.file.resultURL else { return }
                let data = try Data(contentsOf: url)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.saveHistory(with: data)
                    
                    guard let downloadedVC = self.storyboard?.instantiateViewController(withIdentifier: "DownloadedViewController") as? DownloadedViewController else {
                        controller.dismiss(animated: true)
                        return
                    }
                    downloadedVC.modalTransitionStyle = .crossDissolve
                    downloadedVC.modalPresentationStyle = .overFullScreen
                    self.present(downloadedVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    controller.dismiss(animated: true)
                }
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true)
        print("Document picker was cancelled")
    }
}
