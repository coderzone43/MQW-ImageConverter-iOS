import Foundation
import UIKit
import PDFKit
import Zip

class FileConversionManager {
    
    static func convert(
        files: [URL],
        conversionType: ConversionCategory,
        inputType: FileFormat,
        outputType: FileFormat,
        cancellationToken: CancellationToken? = nil,
        progress: @escaping (Double) -> Void,
        completion: @escaping ([URL]) -> Void
    ) {
        var outputURLs: [URL] = []

        DispatchQueue.global(qos: .userInitiated).async {
            for (index, fileURL) in files.enumerated() {
                if cancellationToken?.cancelled() == true {
                    print("Conversion cancelled by user.")
                    break
                }
                
                var result: [URL] = []
                
                switch conversionType {
                case .imageToImage:
                    if let converted = convertImageToImage(inputURL: fileURL, toType: outputType) {
                        result.append(converted)
                    }
                    
                case .imageToPDF:
                    if let converted = convertImageToPDF(inputURL: fileURL) {
                        result.append(converted)
                    }
                    
                case .pdfToImage:
                    if let converted = convertPDFToImages(inputURL: fileURL, toType: outputType) {
                        result.append(converted)
                    }
                    
                default:
                    return
                }
                
                outputURLs.append(contentsOf: result)
                
                let percent = Double(index + 1) / Double(files.count)
                DispatchQueue.main.async {
                    progress(percent)
                }
            }

            DispatchQueue.main.async {
                completion(outputURLs)
            }
        }
    }

    // MARK: - Image → Image
    private static func convertImageToImage(inputURL: URL, toType: FileFormat) -> URL? {
            let image = UIImage(contentsOfFile: inputURL.path)
            var imageData: Data
            var ext: String = ""

            switch toType {
            case .jpg:
                imageData = image?.jpegData(compressionQuality: 1.0) ?? Data()
                ext = "jpg"
            case .png:
                imageData = image?.pngData() ?? Data()
                ext = "png"
            case .webp:
                imageData = image?.pngData() ?? Data()
                ext = "webp"
            default:
                return nil
            }

            let outURL = Utility.saveToConvertedDirectory(data: imageData, url: inputURL, conversionExt: ext)
            print("Converted image saved to: \(String(describing: outURL))")
            return outURL
    }


    // MARK: - Image → PDF

    private static func convertImageToPDF(inputURL: URL) -> URL? {
        guard let image = UIImage(contentsOfFile: inputURL.path) else { return nil }
        let pdfDocument = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfDocument as CFMutableData)!
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        pdfContext.beginPDFPage(nil)
        
        let imageSize = image.size
        let scaleFactor = min(mediaBox.width / imageSize.width, mediaBox.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scaleFactor, height: imageSize.height * scaleFactor)
        let imageRect = CGRect(x: (mediaBox.width - scaledSize.width) / 2,
                               y: (mediaBox.height - scaledSize.height) / 2,
                               width: scaledSize.width,
                               height: scaledSize.height)
        
        pdfContext.draw(image.cgImage!, in: imageRect)
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        let outURL = Utility.saveToConvertedDirectory(data: pdfDocument as Data?, url: inputURL, conversionExt: "pdf")
        print("Converted image saved to: \(String(describing: outURL))")
        return outURL
    }

    // MARK: - PDF → Images

    private static func convertPDFToImages(inputURL: URL, toType: FileFormat) -> URL? {
        guard let pdfDocument = PDFDocument(url: inputURL) else {
            print("Failed to load PDF.")
            return nil
        }
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create temp dir: \(error)")
        }
        
        var imageFileURLs: [URL] = []
        
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            
            UIGraphicsBeginImageContextWithOptions(pageRect.size, false, 1.0)
            guard let context = UIGraphicsGetCurrentContext() else { continue }
            
            context.setFillColor(UIColor.white.cgColor)
            context.fill(pageRect)

            context.translateBy(x: 0, y: pageRect.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()

            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            var ext = "jpg"
            if toType == .png {
                ext = "png"
            }
            
            if let imageData = img?.pngData() {
                let imageURL = tempDir.appendingPathComponent("page_\(i + 1).\(ext)")
                do {
                    try imageData.write(to: imageURL)
                    imageFileURLs.append(imageURL)
                } catch {
                    print("Failed to write image: \(error)")
                }
            }
        }
        
        let tmpDirectory = FileManager.default.temporaryDirectory
        let convertedDirectory = tmpDirectory.appendingPathComponent("Converted")
        
        if !FileManager.default.fileExists(atPath: convertedDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: convertedDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating Converted directory: \(error)")
            }
        }
        
        let fileName = "\(inputURL.deletingPathExtension().lastPathComponent)_converted.zip"
        let outURL = convertedDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: outURL.path) {
            try? fileManager.removeItem(at: outURL)
        }
        
        do {
            try Zip.zipFiles(paths: imageFileURLs, zipFilePath: outURL, password: nil, progress: { progress in
                print("Zipping progress: \(progress * 100)%")
            })
        } catch {
            print("Failed to zip images: \(error)")
            return nil
        }

        return outURL
    }
}
