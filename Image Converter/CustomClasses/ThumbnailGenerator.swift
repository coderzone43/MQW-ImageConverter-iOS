import UIKit
import QuickLookThumbnailing

class ThumbnailGenerator {
    private let defaultThumbnail = UIImage.imgToPdf
    
    init() { }
    
    func getThumbnail(for fileURL: URL, size: CGSize, scale: CGFloat, completion: @escaping (UIImage?, Error?) -> Void) {
        let fileExtension = fileURL.pathExtension.lowercased()
        if fileExtension == "pdf" {
            let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: size, scale: scale, representationTypes: .thumbnail)
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { (thumbnail, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    if let thumbnailImage = thumbnail?.uiImage {
                        completion(thumbnailImage, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            }
        } else if let image = UIImage(contentsOfFile: fileURL.path) {
            DispatchQueue.global(qos: .userInitiated).async {
                let resizedImage = image.resized(to: size, aspectFit: true)
                DispatchQueue.main.async {
                    guard let resizedImage else { return }
                    completion(resizedImage, nil)
                }
            }
        } else {
            completion(nil, NSError(domain: "ThumbnailError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type"]))
        }
    }
    
    func getDefaultThumbnail() -> UIImage {
        return defaultThumbnail
    }
}
