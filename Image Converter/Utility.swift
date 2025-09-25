import Foundation
import UIKit
import PhotosUI
import UniformTypeIdentifiers

class Utility: NSObject {
    
    class func fetchAllowedFileTypes(with tool: Tool?) -> [UTType] {
        guard let tool else { return [] }
        var allowedTypes: [UTType] = []
        let webpType = UTType(filenameExtension: "webp") ?? UTType(mimeType: "image/webp") ?? .image
        
        switch tool.fromFormat {
        case .gif:
            allowedTypes = [.gif]
        case .heic:
            allowedTypes = [.heic, .heif]
        case .heif:
            allowedTypes = [.heic, .heif]
        case .pdf:
            allowedTypes = [.pdf]
        case .png:
            allowedTypes = [.png]
        case .tiff:
            allowedTypes = [.tiff]
        case .webp:
            allowedTypes = [webpType]
        case .jpg:
            allowedTypes = [.jpeg]
        case .img:
            allowedTypes = [.gif, .png, .jpeg, .heic, .heif, .tiff, webpType]
        default:
            allowedTypes = [.image, .item]
        }
        
        return allowedTypes
    }
    
    class func showPaywallScreen(caller: UIViewController){
        if !AppDefaults.shared.isPremium{
            Task{ @MainActor in
                let vc = PaywallViewController.PaywallViewController()
                vc.modalPresentationStyle = .fullScreen
                caller.present(vc, animated: true)
            }
        }
    }
    
    class func connected() -> Bool {
        let reachibility = Reachability.forInternetConnection()
        let networkStatus = reachibility?.currentReachabilityStatus()
        return networkStatus != NotReachable
    }
    
    class func showAlert(caller: UIViewController, title: String?, message: String) -> Void {
        let alert = UIAlertController(title:title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            caller.present(alert, animated: true, completion: nil)
        }
    }
    
    class func noInternetAlert(caller: UIViewController){
        let alert = UIAlertController(title: Constants.appName.localized(), message:"Please Check Your Internet Connection.".localized(), preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            caller.present(alert, animated: true, completion: nil)
        }
    }
    
    class func showSettingAlert(caller: UIViewController, title: String?, message: String, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: { _ in
            completion(true)
        }))
        DispatchQueue.main.async {
            caller.present(alert, animated: true, completion: nil)
        }
    }
    
    class func saveToConvertedDirectory(data: Data?, url: URL? = nil, name: String? = nil, conversionExt: String? = nil) -> URL? {
        guard let data = data else { return nil }
        
        let tmpDirectory = FileManager.default.temporaryDirectory
        let convertedDirectory = tmpDirectory.appendingPathComponent("Converted")
        
        if !FileManager.default.fileExists(atPath: convertedDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: convertedDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating Converted directory: \(error)")
                return nil
            }
        }
        
        var fileName: String = "converted.jpg"
        
        if conversionExt == nil {
            if let url = url {
                fileName = "\(url.deletingPathExtension().lastPathComponent)_converted.\(url.pathExtension)"
            } else {
                fileName = name ?? fileName
            }
        } else {
            if let url = url, let conversionExt = conversionExt {
                fileName = "\(url.deletingPathExtension().lastPathComponent)_converted.\(conversionExt)"
            }
        }
        
        let fileURL = convertedDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("Image saved to \(fileURL.path)")
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}
