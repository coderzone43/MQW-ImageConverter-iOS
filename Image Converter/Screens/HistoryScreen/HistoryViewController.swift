import UIKit
import PhotosUI
import SDWebImage

let categories: [String] = ["All", "JPG Conversions", "PNG Conversions", "PDF Conversions", "Tools"]

final class HistoryViewController: UIViewController {

    @IBOutlet weak var customNavbar: CustomNavbar!
    @IBOutlet weak var customSearchBar: UITextField!
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var historyCollectionView: UICollectionView!
    @IBOutlet weak var emptyContainer: UIView!

    private var historyData: [CDHistory] = []
    private var filteredHistory: [CDHistory] = []
    private var selectedCategoryIndex: Int = 0
    private var currentSearchText: String = ""
    private var searchDebounceTimer: Timer?
    private var selectedHistoryItem: CDHistory?

    private var previousLayoutSize = CGSize.zero

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyContainer.isHidden = true
        customNavbar.screenTitle.text = "History"
        customNavbar.delegate = self
        setupCollectionViews()
        setupSearchBar()

        let first = IndexPath(item: 0, section: 0)
        categoriesCollectionView.selectItem(at: first, animated: false, scrollPosition: [])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Invalidate layout only if the collection view's size has changed.
        if historyCollectionView.bounds.size != previousLayoutSize {
            historyCollectionView.collectionViewLayout.invalidateLayout()
            previousLayoutSize = historyCollectionView.bounds.size
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCollectionView()
    }

    // MARK: - Data
    private func fetchHistoryData() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.historyData = try HistoryRepository.shared.fetchAllHistory()
                DispatchQueue.main.async {
                    self.applyFiltersAndRefreshUI()
                }
            } catch {
                print("Error fetching history data: \(error)")
                DispatchQueue.main.async {
                    self.historyData = []
                    self.applyFiltersAndRefreshUI()
                }
            }
        }
    }

    private func reloadCollectionView() {
        fetchHistoryData()
    }

    // MARK: - Search
    private func setupSearchBar() {
        customSearchBar.layer.cornerRadius = 10
        customSearchBar.layer.borderWidth = 1
        customSearchBar.layer.borderColor = UIColor.systemBackground.cgColor
        customSearchBar.clipsToBounds = true
        customSearchBar.clearButtonMode = .whileEditing
        customSearchBar.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
        customSearchBar.returnKeyType = .done
    }

    // MARK: - Filtering
    private func applyFiltersAndRefreshUI() {
        var filteredByCategory: [CDHistory]

        if categories[selectedCategoryIndex] == "All" {
            filteredByCategory = historyData
        } else if categories[selectedCategoryIndex] == "Tools" {
            filteredByCategory = historyData.filter { $0.action.lowercased() != ConversionAction.convert.rawValue }
        } else {
            filteredByCategory = historyData.filter { $0.type.lowercased() == categories[selectedCategoryIndex].prefix(3).lowercased() }
        }

        let q = currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if q.isEmpty {
                filteredHistory = filteredByCategory
        } else {
            filteredHistory = filteredByCategory.filter { item in
                let title = (item.title).lowercased()
                let id = (item.id).lowercased()
                let type = (item.type).lowercased()
                return title.contains(q) || id.contains(q) || type.contains(q)
            }
        }

        let isEmpty = filteredHistory.isEmpty
        historyCollectionView.isHidden = isEmpty
        emptyContainer.isHidden = !isEmpty

        historyCollectionView.performBatchUpdates({
            historyCollectionView.reloadSections(IndexSet(integer: 0))
        }, completion: nil)
    }

    // MARK: - Collection Views
    private func setupCollectionViews() {
        categoriesCollectionView.register(CategoryCollectionViewCell.nib(), forCellWithReuseIdentifier: CategoryCollectionViewCell.Identifier)
        categoriesCollectionView.delegate = self
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.allowsSelection = true

        historyCollectionView.register(HistoryCollectionViewCell.nib(), forCellWithReuseIdentifier: HistoryCollectionViewCell.Identifier)
        historyCollectionView.dataSource = self
        historyCollectionView.delegate = self
    }
}

// MARK: - UICollectionViewDataSource / Delegate
extension HistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoriesCollectionView {
            return categories.count
        } else {
            return filteredHistory.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoriesCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CategoryCollectionViewCell.Identifier,
                for: indexPath
            ) as? CategoryCollectionViewCell else { return UICollectionViewCell() }

            cell.configure(with: categories[indexPath.item])
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HistoryCollectionViewCell.Identifier,
                for: indexPath
            ) as? HistoryCollectionViewCell else { return UICollectionViewCell() }

            cell.delegate = self
            let historyItem = filteredHistory[indexPath.item]
            cell.configure(with: historyItem)
            
            // Lazy load image
            if historyItem.category == ConversionCategory.imageToImage.rawValue || historyItem.category == ConversionCategory.imageToPDF.rawValue {
                let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = historyItem.title
                let fileURL = directory.appendingPathComponent(fileName)
                cell.imageView.sd_setImage(with: fileURL, completed: nil)
            } else if historyItem.category == ConversionCategory.imageToText.rawValue {
                cell.imageView.image = UIImage.extractTextIcon
            } else if historyItem.category == ConversionCategory.pdfToImage.rawValue || historyItem.category == ConversionCategory.imageToZip.rawValue {
                cell.imageView.image = UIImage.convertToZipIcon
            }
            
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoriesCollectionView {
            selectedCategoryIndex = indexPath.item
            applyFiltersAndRefreshUI()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HistoryViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionView == categoriesCollectionView ? 12 : 16
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoriesCollectionView {
            let label = UILabel()
            label.text = categories[indexPath.item]
            label.font = UIFont.systemFont(ofSize: 16)
            
            let maxWidth = collectionView.frame.width
            let size = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
            return CGSize(width: size.width + 32, height: 44)
        } else {
            let isLandscape = UIDevice.current.orientation.isLandscape || collectionView.traitCollection.verticalSizeClass == .compact
            let cellsPerRow: CGFloat = DeviceType.isIpad ? (isLandscape ? 5 : 3) : (isLandscape ? 3 : 2)
            let width = (collectionView.frame.width - (cellsPerRow - 1) * 12) / cellsPerRow
            return CGSize(width: width, height: 236)
        }
    }
}

// MARK: - HistoryCollectionViewCellDelegate
extension HistoryViewController: HistoryCollectionViewCellDelegate {

    func showDownloadAlert() {
        guard let downloadedVC = storyboard?.instantiateViewController(withIdentifier: "DownloadedViewController") as? DownloadedViewController else { return }
        downloadedVC.modalTransitionStyle = .crossDissolve
        downloadedVC.modalPresentationStyle = .overFullScreen
        present(downloadedVC, animated: true)
    }

    func inputFileName(completion: @escaping (String?) throws -> Void) {
        let alertController = UIAlertController(title: "Enter File Name", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter the file name here"
            textField.textAlignment = .center
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alertController.textFields?.first, let newText = textField.text, !newText.isEmpty else {
                try? completion(" ")
                return
            }
            try? completion(newText)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            try? completion(nil)
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func saveFileToSelectedLocation(selectedHistoryItem: CDHistory) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [getSourceFileURL(for: selectedHistoryItem)], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    func getSourceFileURL(for selectedHistoryItem: CDHistory) -> URL {
        let sourceURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return sourceURL.appendingPathComponent(selectedHistoryItem.title)
    }

    func historyCollectionViewImageViewTapped(_ cell: HistoryCollectionViewCell, history: CDHistory, url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            let documentController = UIDocumentInteractionController(url: url)
            documentController.delegate = self
            documentController.presentPreview(animated: true)
        } else {
            print("PDF file does not exist at path: \(url.path)")
        }
    }

    func historyCollectionViewCellSettingsButtonTapped(_ cell: HistoryCollectionViewCell, history: CDHistory) {
        selectedHistoryItem = history
        let menu = UIAlertController(title: "Choose an Action", message: nil, preferredStyle: .actionSheet)

        menu.addAction(UIAlertAction(title: "Download", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            if history.category == ConversionCategory.imageToImage.rawValue {
                if let image = cell.imageView.image {
                    PHPhotoLibrary.requestAuthorization { status in
                        DispatchQueue.main.async {
                            switch status {
                            case .authorized, .limited:
                                PHPhotoLibrary.shared().performChanges({
                                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                                }) { success, error in
                                    if success {
                                        print("Image saved successfully!")
                                        DispatchQueue.main.async {
                                            self.showDownloadAlert()
                                        }
                                    } else if let error = error {
                                        print("Failed to save image: \(error.localizedDescription)")
                                    }
                                }
                            case .denied, .restricted, .notDetermined:
                                print("Permission denied.")
                            @unknown default:
                                print("Unknown authorization status.")
                            }
                        }
                    }
                }
            } else {
                self.saveFileToSelectedLocation(selectedHistoryItem: history)
            }
        }))

        menu.addAction(UIAlertAction(title: "Rename", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            inputFileName { newName in
                guard let newName else { return }
                guard !newName.isEmpty else {
                    let alert = UIAlertController(
                        title: "Invalid Name",
                        message: "The name cannot be empty.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                do {
                    let regex = try Regex("[a-zA-Z0-9]+")
                    if try regex.firstMatch(in: newName) != nil {
                        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let newFileName = newName + "." + history.type
                        let newFileURL = directory.appendingPathComponent(newFileName)

                        if FileManager.default.fileExists(atPath: newFileURL.path) {
                            let alert = UIAlertController(
                                title: "Name Already Exists",
                                message: "A history with the name '\(newName)' already exists. Please choose a different name.",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            return
                        }

                        do {
                            let fileName = history.title
                            let fileURL = directory.appendingPathComponent(fileName)

                            history.title = newFileName
                            try HistoryRepository.shared.updateHistory()
                            self.reloadCollectionView()

                            try FileManager.default.moveItem(at: fileURL, to: newFileURL)
                            print("✅ File moved to: \(newFileURL)")
                        } catch {
                            print("Failed to update history item: \(error)")
                        }
                    } else {
                        let alert = UIAlertController(
                            title: "Invalid Name",
                            message: "The name must contain only letters or numbers.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                } catch {
                    print("Failed to create regex: \(error)")
                }
            }
        }))
        
        menu.addAction(UIAlertAction(title: "Share", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = history.title
            let fileURL = directory.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                activityVC.excludedActivityTypes = [.saveToCameraRoll, .copyToPasteboard]
                activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                    if completed {
                        print("Sharing completed via \(activityType?.rawValue ?? "unknown")")
                    }
                }
                
                if Constants.currentDevice.model == "iPad" {
                    activityVC.popoverPresentationController?.sourceView = self.view
                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    activityVC.popoverPresentationController?.permittedArrowDirections = []
                }
                
                self.present(activityVC, animated: true, completion: nil)
            }
        }))

        menu.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            let alertController = UIAlertController(title: "Delete File?", message: "Are you sure you want to delete this file?", preferredStyle: .alert)
            alertController.view.backgroundColor = UIColor(white: 1, alpha: 0.3)
            alertController.view.layer.cornerRadius = 14
            alertController.view.clipsToBounds = true
            
            let cancelAction = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
                self?.dismiss(animated: true)
            }
            
            let okAction = UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
                guard let self else { return }
                do {
                    try HistoryRepository.shared.deleteHistory(history)
                    self.reloadCollectionView()
                } catch {
                    print("Error deleting history: \(error.localizedDescription)")
                }
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            self?.present(alertController, animated: true, completion: nil)
        }))

        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if Constants.currentDevice.model == "iPad" {
            if let popoverController = menu.popoverPresentationController {
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
        }
        
        present(menu ,animated: true)
    }
}

// MARK: - CustomNavbarDelegate
extension HistoryViewController: CustomNavbarDelegate {
    func didTapProButton() {
        guard let paywallVC = self.storyboard?.instantiateViewController(withIdentifier: "PaywallViewController") as? PaywallViewController else { return }
        paywallVC.modalPresentationStyle = .fullScreen
        present(paywallVC, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension HistoryViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first, let selectedHistoryItem = selectedHistoryItem else { return }
        
        let sourceURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sourceFileURL = sourceURL.appendingPathComponent(selectedHistoryItem.title)
        
        if FileManager.default.fileExists(atPath: sourceFileURL.path) {
            var destinationURL = selectedURL
            if !destinationURL.hasDirectoryPath {
                destinationURL = destinationURL.deletingLastPathComponent()
            }
            let finalDestinationURL = destinationURL.appendingPathComponent(selectedHistoryItem.title)
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    try FileManager.default.copyItem(at: sourceFileURL, to: finalDestinationURL)
                    print("File saved to \(finalDestinationURL.path)")
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        guard let downloadedVC = self.storyboard?.instantiateViewController(withIdentifier: "DownloadedViewController") as? DownloadedViewController else {
                            controller.dismiss(animated: true)
                            return
                        }
                        downloadedVC.modalTransitionStyle = .crossDissolve
                        downloadedVC.modalPresentationStyle = .overFullScreen
                        self.present(downloadedVC, animated: true)
                    }
                } catch {
                    print("Error copying file: \(error)")
                }
            }
        } else {
            print("File does not exist at source path")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

extension HistoryViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

// MARK: - @objc Methods
extension HistoryViewController {
    @objc private func searchTextChanged(_ textField: UITextField) {
        let newText = textField.text ?? ""
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.currentSearchText = newText
            self.applyFiltersAndRefreshUI()
        }
    }
}
