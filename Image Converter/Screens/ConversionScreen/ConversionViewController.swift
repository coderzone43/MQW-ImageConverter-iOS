import UIKit
import QuickLookThumbnailing
import PhotosUI
import Zip

// MARK: - Model
struct File {
    var url: URL
    var image: UIImage?
    var extractedText: String?
    var resultURL: URL?
}

enum erroTypesFor: Error {
    case denied
    case restricted
    case notDetermined
    case unknown
}

// MARK: - ViewController
class ConversionViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var filesCollectionView: UICollectionView!
    @IBOutlet weak var addInfoContainer: UIView!
    @IBOutlet weak var addFilesButton: UIView!
    @IBOutlet weak var convertButton: UIView!
    @IBOutlet weak var buttonLabel: UILabel!
    @IBOutlet weak var customNavbar: SecondaryCustomNavbar!
    @IBOutlet weak var singleImageContainer: UIView!
    @IBOutlet weak var singleImageView: RotatingImageView!
    @IBOutlet weak var singleReplaceButton: UIImageView!
    
    // MARK: State
    var tool: Tool?
    var files: [File] = []
    var isResultScreen: Bool = false
    var settingsData: Any? = nil
    var customPicker: CustomPicker?
    let cropPicker = CropPickerView()
    
    private var currentAngle: CGFloat = 0
    var flipHorizontal: Bool = false
    var flipVertical: Bool = false
    var textWatermarkContainer: TextWatermarkContainer?
    var imageWatermarkContainer: ImageWatermarkContainer?
    var check: Bool? = false
    
    // MARK: Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customNavbar.screenTitle.text = tool?.title
        customNavbar.settingsButton.isHidden = !([.crop, .resize, .rotate, .watermark, .compress].contains(tool?.action) && !isResultScreen)
        customNavbar.delegate = self
        customPicker = CustomPicker(viewController: self, tool: tool)
        customPicker?.delegate = self
        cropPicker.delegate = self
        
        configureCollectionView()
        setupGestures()
        updateUI()
        setupCropView()
    }
    
    // MARK: Setup
    private func configureCollectionView() {
        filesCollectionView.register(FilesCollectionViewCell.nib(), forCellWithReuseIdentifier: FilesCollectionViewCell.Identifier)
        filesCollectionView.register(FilesCollectionViewSecondaryCell.nib(), forCellWithReuseIdentifier: FilesCollectionViewSecondaryCell.Identifier)
        filesCollectionView.dataSource = self
        filesCollectionView.delegate = self
    }
    
    func setupCropView() {
        if tool?.action == .crop {
            singleImageView.isHidden = true
            cropPicker.translatesAutoresizingMaskIntoConstraints = false
            singleImageContainer.addSubview(cropPicker)
            cropPicker.topAnchor.constraint(equalTo: singleImageContainer.topAnchor, constant: 20).isActive = true
            cropPicker.leftAnchor.constraint(equalTo: singleImageContainer.leftAnchor, constant: 20).isActive = true
            cropPicker.rightAnchor.constraint(equalTo: singleImageContainer.rightAnchor, constant: -20).isActive = true
            cropPicker.bottomAnchor.constraint(equalTo: singleImageContainer.bottomAnchor, constant: -20).isActive = true
            cropPicker.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            cropPicker.isUserInteractionEnabled = false
            let image = singleImageView.image
            cropPicker.image = image
            singleImageContainer.bringSubviewToFront(singleReplaceButton)
        }
    }
    
    func setupGestures() {
        addFilesButton.addTapGestureRecognizer(target: self, action: #selector(filesButtonTap))
        convertButton.addTapGestureRecognizer(target: self, action: #selector(convertButtonTap))
    }
    
    func reloadCollectionView() {
        filesCollectionView.reloadData()
        updateUI()
    }
    
    // MARK: Helpers
    func fetchImage(at url: URL) -> UIImage? {
        if let image = UIImage(contentsOfFile: url.path) {
            return image
        } else {
            print("Failed to load image from URL: \(url)")
            return UIImage()
        }
    }
    
    func updateUI() {
        if isResultScreen {
            addInfoContainer.isHidden = true
            addFilesButton.isHidden = true
            buttonLabel.text = files.count == 1 ? "Download" : "Download All"
        } else {
            addInfoContainer.isHidden = files.count > 1
            addFilesButton.isHidden = false
            buttonLabel.text = tool?.action != .convert ? (tool?.action == .watermark ? "Add Watermark" : tool?.title) : "Convert"
            
            if tool?.action != .convert {
                if [.compress, .extractText, .zip].contains(tool?.action) {
                    addFilesButton.isHidden = false
                    filesCollectionView.isHidden = false
                    singleImageContainer.isHidden = true
                    addInfoContainer.isHidden = files.count > 1
                } else {
                    addFilesButton.isHidden = true
                    addInfoContainer.isHidden = true
                    filesCollectionView.isHidden = true
                    singleImageContainer.isHidden = false
                    singleReplaceButton.isUserInteractionEnabled = true
                    singleReplaceButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(replaceButtonTap)))
                    if let firstFile = files.first {
                        singleImageView.image = fetchImage(at: firstFile.url)
                    }
                }
            }
        }
        
        let isButtonEnabled = isResultScreen || (files.count > 0 && tool?.action == .convert) || ((tool?.action != .convert && settingsData != nil) || [.zip, .extractText].contains(tool?.action))
        convertButton.isUserInteractionEnabled = isButtonEnabled
        convertButton.alpha = isButtonEnabled ? 1.0 : 0.5
    }
}

//MARK: - Tool Methods
extension ConversionViewController {
    func applyWatermark() {
        guard let navigationController = self.navigationController else { return }
        let resultVC = getResultVC()
        imageWatermarkContainer?.isSelected = false
        textWatermarkContainer?.isSelected = false
        singleReplaceButton.isHidden = true
        
        resultVC.files[0].resultURL = Utility.saveToConvertedDirectory (
            data: singleImageContainer.asImage()?.jpegData(compressionQuality: 1.0),
            url: files[0].url
        )
        
        singleReplaceButton.isHidden = false
        navigationController.pushViewController(resultVC, animated: true)
    }
    
    func resizeImage() {
        guard let navigationController = self.navigationController else { return }
        let resultVC = getResultVC()
        guard let settingsData = settingsData as? ResizeSettings else { return }
        guard !files.isEmpty else { return }
        guard let image = fetchImage(at: files[0].url) else { return }
        
        if let resizedImage = image.resized(to: CGSize(width: settingsData.width, height: settingsData.height), aspectFit: settingsData.aspectRatioCheck)?.jpegData(compressionQuality: 1.0) {
            resultVC.files[0].resultURL = Utility.saveToConvertedDirectory (
                data: resizedImage,
                url: files[0].url
            )
        } else {
            print("Failed to resize image")
        }
        
        navigationController.pushViewController(resultVC, animated: true)
    }
    
    func cropImage() {
        guard let navigationController = self.navigationController else { return }
        
        let resultVC = getResultVC()
        
        cropPicker.crop { [weak self] (result) in
            if let error = (result.error as NSError?) {
                let alertController = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
                return
            }
            
            if let croppedImage = result.image {
                if let jpegData = croppedImage.jpegData(compressionQuality: 1.0) {
                    resultVC.files[0].resultURL = Utility.saveToConvertedDirectory(data: jpegData, url: self?.files[0].url)
                } else {
                    print("Failed to generate JPEG data from image")
                }
            } else {
                print("No image found in the result")
            }
            
            DispatchQueue.main.async {
                navigationController.pushViewController(resultVC, animated: true)
            }
        }
    }
    
    func rotateImage() {
        guard let navigationController = self.navigationController else { return }
        let resultVC = getResultVC()
        
        if let settingsData = settingsData as? RotateSettings {
            var rotatedImage: UIImage? = nil
            
            if settingsData.straighten == 0 || settingsData.straighten == 90 || settingsData.straighten == 180 || settingsData.straighten == 270 {
                rotatedImage = getRotatedImage(
                    from: singleImageView,
                    angle: CGFloat(settingsData.straighten ?? .zero),
                    flipHorizontal: settingsData.flipHorizontal,
                    flipVertical: settingsData.flipVertical
                )
            } else {
                rotatedImage = getTransformedImage(
                    from: singleImageView,
                    angle: CGFloat(settingsData.straighten ?? .zero),
                    flipHorizontal: settingsData.flipHorizontal,
                    flipVertical: settingsData.flipVertical
                )
            }
            
            resultVC.files[0].resultURL = Utility.saveToConvertedDirectory (
                data: rotatedImage?.jpegData(compressionQuality: 1.0),
                url: files[0].url
            )
        }
        
        navigationController.pushViewController(resultVC, animated: true)
    }
    
    func convertToZip() {
        guard let navigationController = self.navigationController else { return }
        let resultVC = getResultVC()
        let urls: [URL] = resultVC.files.map(\.self.url)
        
        if let zipData = zipFiles(files: urls) {
            resultVC.files[0].resultURL = Utility.saveToConvertedDirectory (
                data: zipData,
                name: files[0].url.deletingPathExtension().lastPathComponent + ".zip"
            )
        } else {
            print("Failed to create ZIP file")
        }
        
        for (index, var file) in resultVC.files.enumerated() {
            file.resultURL = resultVC.files[0].resultURL
            resultVC.files[index] = file
        }
        
        navigationController.pushViewController(resultVC, animated: true)
    }

    
    func extractText() {
        let cancelToken = CancellationToken()
        guard let loaderVC = storyboard?.instantiateViewController(identifier: "ProcessingViewController") as? ProcessingViewController else { return }
        let ocrManager = OCRManager()
        loaderVC.heading = "Extracting Text..."
        loaderVC.cancellationToken = cancelToken
        loaderVC.modalTransitionStyle = .crossDissolve
        loaderVC.modalPresentationStyle = .overFullScreen
        loaderVC.onCancel = {
            cancelToken.cancel()
        }
        present(loaderVC, animated: true)
        ocrManager.extractText(from: files.map(\.self.url), cancellationToken: cancelToken, progressHandler: { progress in
            DispatchQueue.main.async {
                if !cancelToken.cancelled() {
                    loaderVC.updateProgress(progress)
                }
            }
        }) { [weak self] texts, wasCancelled in
            guard let self else { return }
            DispatchQueue.main.async {
                loaderVC.dismiss(animated: true)
                guard !wasCancelled else { return }
                
                var check = false
                for text in texts {
                    if !text.isEmpty {
                        check = true
                        break
                    }
                }
                
                guard let navigationController = self.navigationController else { return }
                
                if check {
                    if self.files.count == 1 {
                        guard let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "TextResultViewController") as? TextResultViewController else { return }
                        guard let file = self.files.first else { return }
                        
                        resultVC.file = file
                        resultVC.file.extractedText = texts.first ?? ""
                        
                        if resultVC.file.extractedText != "" && resultVC.file.extractedText != nil {
                            resultVC.file.resultURL = Utility.saveToConvertedDirectory(
                                data: texts.first?.data(using: .utf8),
                                name: file.url.deletingPathExtension().lastPathComponent + ".txt"
                            )
                        }
                        
                        navigationController.pushViewController(resultVC, animated: true)
                    } else {
                        let resultVC = self.getResultVC()
                        for (index, var file) in resultVC.files.enumerated() {
                            file.extractedText = texts[index]
                            
                            if file.extractedText != "" && file.extractedText != nil {
                                file.resultURL = Utility.saveToConvertedDirectory (
                                    data: file.extractedText?.data(using: .utf8),
                                    name: file.url.deletingPathExtension().lastPathComponent + ".txt"
                                )
                            }
                            
                            resultVC.files[index] = file
                        }
                        navigationController.pushViewController(resultVC, animated: true)
                    }
                } else {
                    self.dismiss(animated: false) {
                        let alert = NoTextAlert(singleFile: false)
                        alert.present(from: self)
                    }
                }
            }
        }
    }
    
    func compressImages() {
        if files.count > 0 {
            let cancelToken = CancellationToken()
            guard let loaderVC = storyboard?.instantiateViewController(identifier: "ProcessingViewController") as? ProcessingViewController else { return }
            loaderVC.heading = "Compressing Images..."
            loaderVC.cancellationToken = cancelToken
            loaderVC.modalTransitionStyle = .crossDissolve
            loaderVC.modalPresentationStyle = .overFullScreen
            loaderVC.onCancel = {
                cancelToken.cancel()
                CompressionManager.shared.cancel()
            }
            present(loaderVC, animated: true)
            
            compressAllImages(progressHandler: { progress in
                loaderVC.updateProgress(Double(progress))
            }, completion: { [weak self] in
                if !cancelToken.cancelled() {
                    guard let self else { return }
                    guard let navigationController = self.navigationController else { return }
                    loaderVC.dismiss(animated: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let resultVC = self.getResultVC()
                        navigationController.pushViewController(resultVC, animated: true)
                    }
                }
            })
        }
    }
    
    func typeConversions() {
        if files.count > 0 {
            let cancelToken = CancellationToken()
            guard let loaderVC = storyboard?.instantiateViewController(identifier: "ProcessingViewController") as? ProcessingViewController else { return }
            loaderVC.heading = "Conversion in progress..."
            loaderVC.cancellationToken = cancelToken
            loaderVC.modalTransitionStyle = .crossDissolve
            loaderVC.modalPresentationStyle = .overFullScreen
            loaderVC.onCancel = {
                cancelToken.cancel()
                CompressionManager.shared.cancel()
            }
            present(loaderVC, animated: true)
            
            guard let tool else { return }
            FileConversionManager.convert(
                files: files.map(\.url),
                conversionType: tool.type,
                inputType: tool.fromFormat,
                outputType: tool.toFormat,
                cancellationToken: cancelToken,
                progress: { percent in
                    loaderVC.updateProgress(percent)
                },
                completion: { [weak self] results in
                    if !cancelToken.cancelled() {
                        guard let self else { return }
                        guard let navigationController = self.navigationController else { return }
                        loaderVC.dismiss(animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let resultVC = self.getResultVC()
                            
                            for (index, var file) in resultVC.files.enumerated() {
                                if results.isEmpty { return }
                                file.resultURL = results[index]
                                resultVC.files[index] = file
                            }
                            
                            navigationController.pushViewController(resultVC, animated: true)
                        }
                    }
                }
            )
        }
    }
}

//MARK: - Result Screen Methods
extension ConversionViewController {
    func saveHistory(with data: Data) {
        guard let tool else { return }
        var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let date = Date()
        let id = UUID().uuidString
        let title = "\(tool.fromFormat.rawValue.uppercased())-to-\(tool.toFormat.rawValue.uppercased())-\(id).\(tool.type == .pdfToImage ? "zip" : tool.toFormat.rawValue.lowercased())"
        directory.appendPathComponent(title)
        
        do {
            try data.write(to: directory)
            print("History saved at \(directory)")
        } catch {
            print("Failed to save History.")
        }
        
        let history = History(
            id: id,
            toType: tool.toFormat,
            category: tool.type,
            action: tool.action,
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
    
    func saveResultImage() {
        if let sourceURL = files[0].resultURL, let image = UIImage(contentsOfFile: sourceURL.path) {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                guard let self else { return }
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAsset(from: image)
                        }) { success, error in
                            if success {
                                print("Image saved successfully!")
                                if let data = image.jpegData(compressionQuality: 1.0) {
                                    self.saveHistory(with: data)
                                    DispatchQueue.main.async {
                                        self.showDownloadAlert()
                                    }
                                }
                            } else if let error = error {
                                print("Failed to save image: \(error.localizedDescription)")
                                Utility.showSettingAlert(caller: self, title: "Permission Denied.".localized(), message: "Please allow access to your photo library.".localized()) { bool in
                                    if bool, let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }
                            }
                        }
                    case .denied, .restricted, .notDetermined:
                        Utility.showSettingAlert(caller: self, title: "Permission Denied.".localized(), message: "Please allow access to your photo library.".localized()) { bool in
                            if bool, let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                    @unknown default:
                        print("Unknown authorization status.")
                    }
                }
            }
        }
    }
    
    func saveResultDocument(resultURL: URL) {
        if !AppDefaults.shared.reviewRequested {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self, let reviewVC = storyboard?.instantiateViewController(withIdentifier: "ReviewViewController") as? ReviewViewController else { return }
                present(reviewVC, animated: true)
            }
        }
        
        let documentPicker = UIDocumentPickerViewController(forExporting: [resultURL], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    
    func showDownloadAlert() {
        guard let downloadedVC = storyboard?.instantiateViewController(withIdentifier: "DownloadedViewController") as? DownloadedViewController else { return }
        downloadedVC.modalTransitionStyle = .crossDissolve
        downloadedVC.modalPresentationStyle = .overFullScreen
        present(downloadedVC, animated: true)
    }
    
    func downloadResults() {
        if !AppDefaults.shared.reviewRequested {
            guard let reviewVC = storyboard?.instantiateViewController(withIdentifier: "ReviewViewController") as? ReviewViewController else { return }
            reviewVC.modalPresentationStyle = .overFullScreen
            reviewVC.onDismiss = { [weak self] in
                self?.proceedWithDownloadResults()
            }
            present(reviewVC, animated: true)
        } else {
            proceedWithDownloadResults()
        }
    }

    private func proceedWithDownloadResults() {
        guard let tool else { return }
        
        if tool.action == .extractText {
            let textfiles = files.filter { $0.extractedText != nil && !$0.extractedText!.isEmpty }
            if textfiles.count == 1 {
                guard let url = textfiles[0].resultURL else { return }
                saveResultDocument(resultURL: url)
            } else {
                let resultFiles = textfiles.compactMap(\.resultURL)
                if let zipdata = zipFiles(files: resultFiles) {
                    do {
                        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("Archive-\(UUID().uuidString).zip")
                        try zipdata.write(to: temporaryURL)
                        saveResultDocument(resultURL: temporaryURL)
                    } catch {
                        print("Error creating zip in memory: \(error)")
                    }
                }
            }
        } else {
            if files.count == 1 || tool.action == .zip {
                if tool.type == .imageToImage {
                    saveResultImage()
                } else {
                    guard let url = files[0].resultURL else { return }
                    saveResultDocument(resultURL: url)
                }
            } else {
                let resultFiles = files.compactMap(\.resultURL)
                if let zipdata = zipFiles(files: resultFiles) {
                    do {
                        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("Archive-\(UUID().uuidString).zip")
                        try zipdata.write(to: temporaryURL)
                        saveResultDocument(resultURL: temporaryURL)
                    } catch {
                        print("Error creating zip in memory: \(error)")
                    }
                }
            }
        }
    }

}

// MARK: - @objc Actions
extension ConversionViewController {
    @objc func filesButtonTap() {
        customPicker?.allowMultiSelection = true
        customPicker?.showActionSheet()
    }
    
    @objc func replaceButtonTap() {
        customPicker?.allowMultiSelection = false
        customPicker?.showActionSheet()
    }
    
    @objc func convertButtonTap() {
        if isResultScreen {
            if AppDefaults.shared.canSendQuery {
                downloadResults()
                AppDefaults.shared.incrementFreeHitsCount()
            } else {
                guard let paywallVC = self.storyboard?.instantiateViewController(withIdentifier: "PaywallViewController") as? PaywallViewController else { return }
                paywallVC.modalPresentationStyle = .fullScreen
                present(paywallVC, animated: true)
            }
        } else {
            applyTool()
        }
    }
}

//MARK: - Tools Helper Methods
extension ConversionViewController {
    //MARK: Rotation
    func getTransformedImage(from imageView: UIImageView, angle: CGFloat, flipHorizontal: Bool, flipVertical: Bool) -> UIImage? {
        guard let image = imageView.image else { return nil }
        let imageSize = image.size
        var transform = CGAffineTransform.identity
        
        if flipHorizontal {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        if flipVertical {
            transform = transform.scaledBy(x: 1, y: -1)
        }
        
        transform = transform.rotated(by: angle * (.pi / 180))
        UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: imageSize.width / 2, y: imageSize.height / 2)
        ctx.concatenate(transform)
        ctx.translateBy(x: -imageSize.width / 2, y: -imageSize.height / 2)
        image.draw(at: CGPoint.zero)
        let transformedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return transformedImage
    }
    
    func getRotatedImage(from imageView: UIImageView, angle: CGFloat, flipHorizontal: Bool, flipVertical: Bool) -> UIImage? {
        guard let image = imageView.image else { return nil }
        
        let imageSize = image.size
        var transform = CGAffineTransform.identity
        
        if flipHorizontal {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        if flipVertical {
            transform = transform.scaledBy(x: 1, y: -1)
        }
        
        transform = transform.rotated(by: angle * (.pi / 180))
        let rotatedSize = CGSize(width: abs(imageSize.width * transform.a) + abs(imageSize.height * transform.c),
                                 height: abs(imageSize.width * transform.b) + abs(imageSize.height * transform.d))
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        ctx.concatenate(transform)
        ctx.translateBy(x: -imageSize.width / 2, y: -imageSize.height / 2)
        image.draw(at: CGPoint.zero)
        
        let transformedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return transformedImage
    }
    
    // MARK: Zipping
    func zipFiles(files: [URL]) -> Data? {
        do {
            let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("Archive-\(UUID().uuidString).zip")
            try Zip.zipFiles(paths: files, zipFilePath: temporaryURL, password: nil, progress: nil)
            let zipData = try Data(contentsOf: temporaryURL)
            try FileManager.default.removeItem(at: temporaryURL)
            return zipData
        } catch {
            print("Error creating zip in memory: \(error)")
            return nil
        }
    }
    
    // MARK: Compression
    func compressImage(_ item: UIImage?, sliderValue: Double) -> UIImage? {
        var newItem: UIImage?
        guard let item = item else { return newItem }
        let compressionFactor = max(0.1, min(1.0, 1.0 - (sliderValue / 100.0)))
        let newSize = CGSize(width: item.size.width * CGFloat(compressionFactor),
                             height: item.size.height * CGFloat(compressionFactor))
        UIGraphicsBeginImageContextWithOptions(newSize, false, item.scale)
        item.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let resizedImage = resizedImage {
            guard let imageData = resizedImage.jpegData(compressionQuality: CGFloat(compressionFactor)) ?? resizedImage.pngData() else {
                return item
            }
            
            newItem = UIImage(data: imageData)
        }
        
        return newItem
    }
    
    func compressAllImages(progressHandler: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        let sliderValue: Double
        if let settingsData = settingsData as? Int {
            sliderValue = Double(settingsData)
        } else {
            sliderValue = 50.0
        }
        
        let total = files.count
        CompressionManager.shared.reset()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            for (index, _) in self.files.enumerated() {
                if CompressionManager.shared.cancelled { break }
                
                self.files[index].resultURL = Utility.saveToConvertedDirectory(
                    data: self.compressImage(self.fetchImage(at: self.files[index].url), sliderValue: sliderValue)?.jpegData(compressionQuality: 1.0),
                    url: self.files[index].url
                )
                
                if CompressionManager.shared.cancelled { break }
                let progress = Int(Double(index + 1) / Double(total) * 100.0)
                
                DispatchQueue.main.async {
                    progressHandler(progress)
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    //MARK: Miscellaneous
    func applyTool() {
        switch tool?.action {
        case .watermark:
            applyWatermark()
        case .rotate:
            rotateImage()
        case .zip:
            convertToZip()
        case .crop:
            cropImage()
        case .resize:
            resizeImage()
        case .compress:
            compressImages()
        case .extractText:
            extractText()
        case .convert:
            typeConversions()
        default:
            break
        }
    }
    
    func getResultVC() -> ConversionViewController {
        guard let resultVC = storyboard?.instantiateViewController(withIdentifier: "ConversionViewController") as? ConversionViewController else { return ConversionViewController() }
        resultVC.tool = tool
        resultVC.files = self.files
        resultVC.isResultScreen = true
        return resultVC
    }
    
    func inputFileName(completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "Enter File Name", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter the file name here"
            textField.textAlignment = .center
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alertController.textFields?.first, let newText = textField.text, !newText.isEmpty else {
                completion(nil)
                return
            }
            completion(newText)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(nil)
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
