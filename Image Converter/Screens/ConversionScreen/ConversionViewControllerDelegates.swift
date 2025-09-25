import UIKit
import PDFKit
import QuickLookThumbnailing
import PhotosUI
import Zip

enum FileError: Equatable {
    case tooLarge
    case locked([URL])
    case invalid([URL])
    case unsupported(URL, String)
    
    var priority: Int {
        switch self {
        case .tooLarge: return 4 // Highest priority
        case .locked: return 3
        case .invalid: return 2
        case .unsupported: return 1 // Lowest priority
        }
    }
    
    var alertDetails: (title: String, message: String) {
        switch self {
        case .tooLarge:
            return (title: "Files Too Large", message: "The selected files are larger than 100MB. Please choose smaller files.")
        case .locked(let urls):
            let fileNames = urls.map { $0.lastPathComponent }.joined(separator: ", ")
            return (title: "File(s) Locked", message: "The following files are locked: \(fileNames). Please unlock them or choose different files.")
        case .invalid(let urls):
            let fileNames = urls.map { $0.lastPathComponent }.joined(separator: ", ")
            return (title: "Invalid File(s)", message: "The following files are not valid: \(fileNames). Please choose different files.")
        case .unsupported(let url, let errorMessage):
            return (title: "Error", message: "Unable to access file at \(url.lastPathComponent): \(errorMessage)")
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension ConversionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let tool = tool else { return 0 }
        return (isResultScreen && tool.action == .zip) ? 1 : files.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = dequeueCell(for: indexPath, collectionView: collectionView) else {
            print("Failed to dequeue cell for identifier: \(tool?.action != .convert ? FilesCollectionViewSecondaryCell.Identifier : FilesCollectionViewCell.Identifier)")
            return UICollectionViewCell()
        }
        
        guard let tool else { return cell }
        let file = files[indexPath.row]
        
        if isResultScreen {
            let isSingleResult = tool.action == .zip

            if isSingleResult {
                (cell as? FilesCollectionViewCell)?.configure(with: UIImage.convertToZipIcon, name: UUID().uuidString + ".zip", isResultScreen)
            } else {
                if tool.type == .pdfToImage {
                    (cell as? FilesCollectionViewCell)?.configure(with: UIImage.convertToZipIcon, name: UUID().uuidString + ".zip", isResultScreen)
                } else if tool.type == .imageToText {
                    configureCellWithThumbnail(cell, fileURL: file.url, indexPath: indexPath, collectionView: collectionView)
                } else {
                    guard let resultURL = file.resultURL else { return cell }
                    configureCellWithThumbnail(cell, fileURL: resultURL, indexPath: indexPath, collectionView: collectionView)
                }
            }
        } else {
            configureCellWithThumbnail(cell, fileURL: file.url, indexPath: indexPath, collectionView: collectionView)
        }
        
        if let secondaryCell = cell as? FilesCollectionViewSecondaryCell {
            secondaryCell.delegate = self
        } else if let primaryCell = cell as? FilesCollectionViewCell {
            primaryCell.delegate = self
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isResultScreen && tool?.title == "Extract Text" {
            if let text = files[indexPath.row].extractedText, !text.isEmpty {
                guard let navigationController = self.navigationController else { return }
                guard let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "TextResultViewController") as? TextResultViewController else { return }
                resultVC.file = files[indexPath.item]
                navigationController.pushViewController(resultVC, animated: true)
            } else {
                let alert = NoTextAlert(singleFile: true)
                alert.present(from: self)
            }
        }
    }
    
    private func dequeueCell(for indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell? {
        let identifier: String
        if isResultScreen {
            identifier = FilesCollectionViewCell.Identifier
        } else {
            identifier = (tool?.action != .convert) ? FilesCollectionViewSecondaryCell.Identifier : FilesCollectionViewCell.Identifier
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    
    private func configureCellWithThumbnail(_ cell: UICollectionViewCell, fileURL: URL, indexPath: IndexPath, collectionView: UICollectionView) {
        guard let tool else { return }
        let isOtherTool = tool.action != .convert
        let thumbnailSize = isOtherTool ? CGSize(width: 174, height: 174) : CGSize(width: 48, height: 48)
        let fileName = fileURL.lastPathComponent
        let thumbnailGenerator = ThumbnailGenerator()
        
        configureCell(cell, with: thumbnailGenerator.getDefaultThumbnail(), name: tool.type == .imageToText ? fileURL.deletingPathExtension().lastPathComponent + ".txt" : fileName, text: files[indexPath.item].extractedText, isResultScreen: isResultScreen)
        
        if tool.type == .imageToPDF || tool.type == .pdfToImage {
            thumbnailGenerator.getThumbnail(for: fileURL, size: thumbnailSize, scale: UIScreen.main.scale) { [weak self] (thumbnailImage, error) in
                guard error == nil, let thumbnailImage = thumbnailImage,
                      let currentIndexPath = collectionView.indexPath(for: cell),
                      currentIndexPath == indexPath else {
                    if let error = error {
                        print("Thumbnail generation failed: \(error)")
                    }
                    return
                }
                
                self?.configureCell(cell, with: thumbnailImage, name: fileName, text: self?.files[indexPath.item].extractedText, isResultScreen: self?.isResultScreen ?? false)
            }
        } else {
            configureCell(cell, with: fetchImage(at: fileURL) ?? thumbnailGenerator.getDefaultThumbnail(), name: fileName, text: files[indexPath.item].extractedText, isResultScreen: isResultScreen)
        }
        
    }
    
    private func configureCell(_ cell: UICollectionViewCell, with image: UIImage, name: String?, text: String?, isResultScreen: Bool) {
        if let secondaryCell = cell as? FilesCollectionViewSecondaryCell {
            secondaryCell.configure(with: image)
        } else if let primaryCell = cell as? FilesCollectionViewCell {
            primaryCell.configure(with: image, name: name ?? "", text: text, isResultScreen)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ConversionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isResultScreen {
            return CGSize(width: UIScreen.main.bounds.width - 32, height: 64)
        } else if UIDevice.current.userInterfaceIdiom == .pad && tool?.action != .convert {
            // On iPad and not a result screen with tool.action != .convert, show 3 cells per row with width 174
            let totalWidth = collectionView.frame.width - 32 // Account for insets (16 left + 16 right)
            let itemWidth = 174 // Fixed width for each item
            return CGSize(width: itemWidth, height: 174)
        } else {
            return tool?.action != .convert ? CGSize(width: 174, height: 174) : CGSize(width: UIScreen.main.bounds.width - 32, height: 64)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if isResultScreen {
            return 8
        } else if UIDevice.current.userInterfaceIdiom == .pad && tool?.action != .convert {
            // On iPad and not a result screen with tool.action != .convert
            return 8 // Adjust the line spacing as needed
        } else {
            return tool?.action != .convert ? 20 : 8
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad && tool?.action != .convert {
            // On iPad and not a result screen with tool.action != .convert
            let totalWidth = collectionView.frame.width - 32 // Account for insets (16 left + 16 right)
            let cellWidth = 174 // Fixed width for each item
            let totalSpacing = totalWidth - CGFloat(4 * cellWidth) // Remaining space after placing 3 cells
            let interItemSpacing = totalSpacing / 3 // Divide remaining space equally between the cells
            return max(interItemSpacing, 0) // Ensure non-negative spacing
        } else {
            return 0
        }
    }
}

// MARK: - FilesCollectionViewCellDelegate, FilesCollectionViewSecondaryCellDelegate
extension ConversionViewController: FilesCollectionViewCellDelegate, FilesCollectionViewSecondaryCellDelegate {
    func cancelButtonTap(_ cell: FilesCollectionViewSecondaryCell) {
        presentCancelAlert(cell)
    }
    
    func cancelButtonTap(_ cell: FilesCollectionViewCell) {
        presentCancelAlert(cell)
    }
    
    func presentCancelAlert(_ cell: UICollectionViewCell) {
        if presentedViewController == nil {
            let alertController = UIAlertController(title: "Remove File?", message: "Are you sure you want to remove this file?", preferredStyle: .alert)
            
            alertController.view.backgroundColor = UIColor(white: 1, alpha: 0.3)
            alertController.view.layer.cornerRadius = 14
            alertController.view.clipsToBounds = true
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.dismiss(animated: true)
            }
            let okAction = UIAlertAction(title: "Ok", style: .destructive) { [weak self] _ in
                guard let self else { return }
                guard let indexPath = filesCollectionView.indexPath(for: cell)?.row else { return }
                
                try? FileManager.default.removeItem(at: files[indexPath].url)
                if let resultURL = files[indexPath].resultURL {
                    try? FileManager.default.removeItem(at: resultURL)
                }
                files.remove(at: indexPath)
                reloadCollectionView()
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: - SecondaryCustomNavbarDelegate
extension ConversionViewController: SecondaryCustomNavbarDelegate {
    func settingsButtonTapped() {
        if tool?.action == .resize {
            guard let settingVC = storyboard?.instantiateViewController(withIdentifier: "ResizeSettingsViewController") as? ResizeSettingsViewController else { return }
            settingVC.modalPresentationStyle = .custom
            settingVC.transitioningDelegate = self
            if let firstFile = files.first {
                if let image = fetchImage(at: firstFile.url) {
                    settingVC.originalSize = [Int(image.size.width), Int(image.size.height)]
                }
            }
            settingVC.modifiedSize = settingsData as? ResizeSettings
            present(settingVC, animated: true)
            settingVC.onDismiss = { [weak self] modifiedSize in
                if let modifiedSize = modifiedSize {
                    self?.settingsData = modifiedSize
                    self?.updateUI()
                }
            }
        } else if tool?.action == .compress {
            guard let settingVC = storyboard?.instantiateViewController(withIdentifier: "CompressSettingsViewController") as? CompressSettingsViewController else { return }
            settingVC.modalPresentationStyle = .custom
            settingVC.transitioningDelegate = self
            settingVC.compression = settingsData as? Int
            present(settingVC, animated: true)
            
            settingVC.onDismiss = { [weak self] compression in
                if compression != nil {
                    self?.settingsData = compression
                    self?.updateUI()
                }
            }
        } else if tool?.action == .crop {
            guard let settingVC = storyboard?.instantiateViewController(withIdentifier: "CropSettingsViewController") as? CropSettingsViewController else { return }
            settingVC.modalPresentationStyle = .custom
            settingVC.transitioningDelegate = self
            settingVC.lastSelectedIndexPath = settingsData as? IndexPath
            present(settingVC, animated: true)
            
            settingVC.onDismiss = { [weak self] settings in
                if settings != nil {
                    self?.settingsData = settings
                    self?.cropPicker.isUserInteractionEnabled = true
                    if settings == IndexPath(row: 0, section: 0) {
                        self?.cropPicker.aspectRatio = (self?.cropPicker.image?.size.width ?? 1) / (self?.cropPicker.image?.size.height ?? 1)
                        self?.cropPicker.isUserInteractionEnabled = false
                    } else if settings == IndexPath(row: 1, section: 0) {
                        self?.cropPicker.aspectRatio = 0
                    } else if settings == IndexPath(row: 2, section: 0) {
                        self?.cropPicker.aspectRatio = 1
                    } else if settings == IndexPath(row: 3, section: 0) {
                        self?.cropPicker.aspectRatio = 1 / 2
                    } else if settings == IndexPath(row: 4, section: 0) {
                        self?.cropPicker.aspectRatio = 3 / 4
                    } else if settings == IndexPath(row: 5, section: 0) {
                        self?.cropPicker.aspectRatio = 4 / 5
                    } else if settings == IndexPath(row: 6, section: 0) {
                        self?.cropPicker.aspectRatio = 9 / 16
                    } else if settings == IndexPath(row: 7, section: 0) {
                        self?.cropPicker.aspectRatio = 16 / 9
                    } else if settings == IndexPath(row: 8, section: 0) {
                        self?.cropPicker.aspectRatio = 2 / 1
                    }
                    self?.updateUI()
                }
            }
        } else if tool?.action == .rotate {
            guard let settingVC = storyboard?.instantiateViewController(withIdentifier: "RotateSettingsViewController") as? RotateSettingsViewController else { return }
            settingVC.modalPresentationStyle = .custom
            settingVC.transitioningDelegate = self
            settingVC.settings = settingsData as? RotateSettings
            settingVC.delegate = self
            present(settingVC, animated: true)
            
            settingVC.onDismiss = { [weak self] settings in
                if settings != nil {
                    self?.settingsData = settings
                    self?.updateUI()
                }
            }
        } else if tool?.action == .watermark {
            guard let settingVC = storyboard?.instantiateViewController(withIdentifier: "WatermarkSettingsViewController") as? WatermarkSettingsViewController else { return }
            settingVC.modifiedSettings = settingsData as? WatermarkSettings
            settingVC.delegate = self
            settingVC.modalPresentationStyle = .custom
            settingVC.transitioningDelegate = self
            present(settingVC, animated: true)
            
            settingVC.onDismiss = { [weak self] modifiedSettings in
                self?.settingsData = modifiedSettings
                self?.updateUI()
            }
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension ConversionViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInFromRightAnimator(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInFromRightAnimator(isPresenting: false)
    }
}

// MARK: - RotateSettingsViewControllerDelegate
extension ConversionViewController: RotateSettingsViewControllerDelegate {
    func didUpdateRotation(_ sender: RotateSettingsViewController, settings: RotateSettings) {
        if let angle = settings.straighten {
            singleImageView.rotationAngle = CGFloat(angle)
        }
        singleImageView.flipHorizontal = settings.flipHorizontal
        singleImageView.flipVertical = settings.flipVertical
    }
}

// MARK: - WatermarkSettingsViewControllerDelegate
extension ConversionViewController: WatermarkSettingsViewControllerDelegate {
    func textFieldDidChange(_ textField: String?) {
        let text = textField ?? ""
        singleImageView.isUserInteractionEnabled = true
        if text.isEmpty {
            textWatermarkContainer?.removeFromSuperview()
            textWatermarkContainer = nil
        } else {
            if textWatermarkContainer == nil {
                let newWatermark = TextWatermarkContainer(withText: text)
                newWatermark.delegate = self
                singleImageView.addSubview(newWatermark)
                singleImageView.bringSubviewToFront(newWatermark)
                textWatermarkContainer = newWatermark
            } else {
                textWatermarkContainer?.setText(text)
            }
        }
    }
    
    func textSettingsChanged(opacity: Float?, font: String?, color: UIColor?) {
        textWatermarkContainer?.textSettingsChanged(opacity: opacity, font: font, color: color)
    }
    
    func selectedImageChanged(_ image: UIImage?) {
        singleImageView.isUserInteractionEnabled = true
        if image == nil {
            imageWatermarkContainer?.removeFromSuperview()
            imageWatermarkContainer = nil
        } else {
            if imageWatermarkContainer == nil {
                let newWatermark = ImageWatermarkContainer(withImage: image!)
                newWatermark.delegate = self
                singleImageView.addSubview(newWatermark)
                imageWatermarkContainer = newWatermark
            } else {
                imageWatermarkContainer?.setImage(image!)
            }
        }
    }
    
    func imageSettingsChanged(opacity: Float?) {
        imageWatermarkContainer?.imageSettingsChanged(opacity: opacity)
    }
}

// MARK: - TextWatermarkContainerDelegate
extension ConversionViewController: TextWatermarkContainerDelegate {
    func showTextViewPopUp(text: String) {
        let alertController = UIAlertController(title: "Edit Text", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.text = text
            textField.textAlignment = .center
            textField.font = UIFont(name: self.textWatermarkContainer?.fontNameString ?? "Helvetica", size: self.textWatermarkContainer?.fontSize ?? 40)
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first, let newText = textField.text else { return }
            self?.textWatermarkContainer?.setText(newText)
            if var settingsData = self?.settingsData as? WatermarkSettings {
                settingsData.textField = newText
                self?.settingsData = settingsData
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func watermarkContainerDidCancel(_ container: TextWatermarkContainer) {
        textWatermarkContainer?.removeFromSuperview()
        textWatermarkContainer = nil
        if var settingsData = self.settingsData as? WatermarkSettings {
            if !settingsData.imageMode {
                self.settingsData = nil
            } else {
                settingsData.textMode = false
                settingsData.textField = nil
                settingsData.textOpacity = nil
                settingsData.textColor = nil
                settingsData.textFont = nil
                self.settingsData = settingsData
            }
        }
        updateUI()
    }
}

// MARK: - ImageWatermarkContainerDelegate
extension ConversionViewController: ImageWatermarkContainerDelegate {
    func watermarkContainerDidCancel(_ container: ImageWatermarkContainer) {
        imageWatermarkContainer?.removeFromSuperview()
        imageWatermarkContainer = nil
        if var settingsData = self.settingsData as? WatermarkSettings {
            if !settingsData.textMode {
                self.settingsData = nil
            } else {
                settingsData.imageMode = false
                settingsData.image = nil
                settingsData.imageOpacity = nil
                self.settingsData = settingsData
            }
        }
        updateUI()
    }
}

//MARK: - CustomPickerDelegate
extension ConversionViewController: CustomPickerDelegate {
    func didReceiveFileURLs(urls: [URL]) {
        var validFiles: [File] = []
        let maxSizeInBytes = Int64(100 * 1024 * 1024)
        var totalSize: Int64 = 0
        var errors: [FileError] = []
        
        for file in files {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: file.url.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    totalSize += fileSize
                    if totalSize > maxSizeInBytes {
                        errors.append(.tooLarge)
                        break
                    }
                }
            } catch {
                print("Error accessing file attributes for \(file.url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        // Validate new URLs
        var lockedFiles: [URL] = []
        var invalidFiles: [URL] = []
        
        for url in urls {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                
                // Check file size
                if let fileSize = fileAttributes[.size] as? Int64 {
                    totalSize += fileSize
                    if totalSize > maxSizeInBytes {
                        errors.append(.tooLarge)
                        break
                    }
                }
                
                // Check if file is immutable
                if let isImmutable = fileAttributes[.immutable] as? Bool, isImmutable {
                    lockedFiles.append(url)
                    continue
                }
                
                // Check PDF files
                if url.pathExtension.lowercased() == "pdf" {
                    guard let pdfDocument = PDFDocument(url: url) else {
                        invalidFiles.append(url)
                        continue
                    }
                    if pdfDocument.isLocked {
                        lockedFiles.append(url)
                        continue
                    }
                }
                
                validFiles.append(File(url: url))
            } catch {
                errors.append(.unsupported(url, error.localizedDescription))
            }
        }
        
        if !lockedFiles.isEmpty {
            errors.append(.locked(lockedFiles))
        }
        if !invalidFiles.isEmpty {
            errors.append(.invalid(invalidFiles))
        }
        
        if let highestPriorityError = errors.max(by: { $0.priority < $1.priority }) {
            let (title, message) = highestPriorityError.alertDetails
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            return
        }
        
        if tool?.action != .convert && ![.compress, .extractText, .zip].contains(tool?.action) {
            self.files = []
            if let firstFile = validFiles.first {
                self.files.append(firstFile)
                DispatchQueue.main.async { [weak self] in
                    self?.singleImageView.image = self?.fetchImage(at: firstFile.url)
                    if self?.tool?.action == .crop {
                        self?.cropPicker.image = self?.singleImageView.image
                    }
                }
            }
        } else {
            self.files.append(contentsOf: validFiles)
            DispatchQueue.main.async { [weak self] in
                self?.reloadCollectionView()
            }
        }
    }
}

//MARK: - UIDocumentPickerDelegate
extension ConversionViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self, let tool = self.tool else { return }
                
                if tool.action == .extractText {
                    let textfiles = files.filter { $0.extractedText != nil && !$0.extractedText!.isEmpty }
                    
                    for file in textfiles {
                        do {
                            if let url = file.resultURL {
                                let data = try Data(contentsOf: url)
                                saveHistory(with: data)
                            }
                        } catch {
                            print("Error saving file: \(error.localizedDescription)")
                        }
                    }
                } else {
                    if tool.action == .zip {
                        guard let url = files[0].resultURL else { return }
                        
                        do {
                            let data = try Data(contentsOf: url)
                            saveHistory(with: data)
                        } catch {
                            print("Error saving file: \(error.localizedDescription)")
                        }
                    } else {
                        let resultFiles = files.compactMap(\.resultURL)
                        
                        for file in resultFiles {
                            do {
                                let data = try Data(contentsOf: file)
                                saveHistory(with: data)
                            } catch {
                                print("Error saving file: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                guard let downloadedVC = self.storyboard?.instantiateViewController(withIdentifier: "DownloadedViewController") as? DownloadedViewController else {
                    controller.dismiss(animated: true)
                    return
                }
                downloadedVC.modalTransitionStyle = .crossDissolve
                downloadedVC.modalPresentationStyle = .overFullScreen
                self.present(downloadedVC, animated: true)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true)
        print("Document picker was cancelled")
    }
}

//MARK: - CropPickerViewDelegate
extension ConversionViewController: CropPickerViewDelegate {
    func cropPickerView(_ cropPickerView: CropPickerView, result: CropResult) {
        
    }
}

