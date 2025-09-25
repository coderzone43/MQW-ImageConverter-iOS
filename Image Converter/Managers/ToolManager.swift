import UIKit

enum FileFormat: String, CaseIterable {
    case jpg, png, webp, pdf, heic, heif, tiff, gif, img, zip, txt

    var description: String {
        switch self {
            case .jpg: return "JPG"
            case .png: return "PNG"
            case .webp: return "WebP"
            case .pdf: return "PDF"
            case .heic: return "HEIC"
            case .heif: return "HEIF"
            case .tiff: return "TIFF"
            case .gif: return "GIF"
            case .img: return "IMG"
            case .zip: return "ZIP"
            case .txt: return "TXT"
        }
    }
}

enum ConversionCategory: String {
    case imageToImage
    case imageToPDF
    case pdfToImage
    case imageToZip
    case imageToText
}

enum ConversionAction: String {
    case convert
    case resize
    case rotate
    case watermark
    case compress
    case zip
    case crop
    case extractText
}

struct Tool: Hashable {
    let image: UIImage
    let title: String
    let fromFormat: FileFormat
    let toFormat: FileFormat
    let action: ConversionAction
    let type: ConversionCategory
}

enum ToolType: String, CaseIterable {
    case jpg = "JPG Conversions"
    case png = "PNG Conversions"
//    case webp = "WebP Conversions"
    case pdf = "PDF Tools"
    case other = "Other Tools"
    
    var imagePrefix: String {
        switch self {
        case .jpg: return "Jpg"
        case .png: return "Png"
//        case .webp: return "Webp"
        case .pdf: return "Pdf"
        case .other: return "Other"
        }
    }
    
    var tools: [Tool] {
        let tools: [Tool]
        
        switch self {
        case .jpg:
            tools = [
                Tool(image: UIImage.pngToJpg, title: "PNG to JPG", fromFormat: .png, toFormat: .jpg, action: .convert, type: .imageToImage),
                Tool(image: UIImage.heicToJpg, title: "HEIC to JPG", fromFormat: .heic, toFormat: .jpg, action: .convert, type: .imageToImage),
                Tool(image: UIImage.heifToJpg, title: "HEIF to JPG", fromFormat: .heif, toFormat: .jpg, action: .convert, type: .imageToImage),
                Tool(image: UIImage.tiffToJpg, title: "TIFF to JPG", fromFormat: .tiff, toFormat: .jpg, action: .convert, type: .imageToImage),
                Tool(image: UIImage.gifToJpg, title: "GIF to JPG", fromFormat: .gif, toFormat: .jpg, action: .convert, type: .imageToImage),
                Tool(image: UIImage.webpToJpg, title: "WebP to JPG", fromFormat: .webp, toFormat: .jpg, action: .convert, type: .imageToImage),
                Tool(image: UIImage.pdfToJpg, title: "PDF to JPG", fromFormat: .pdf, toFormat: .jpg, action: .convert, type: .pdfToImage)
            ]
        case .png:
            tools = [
                Tool(image: UIImage.jpgToPng, title: "JPG to PNG", fromFormat: .jpg, toFormat: .png, action: .convert, type: .imageToImage),
                Tool(image: UIImage.heicToPng, title: "HEIC to PNG", fromFormat: .heic, toFormat: .png, action: .convert, type: .imageToImage),
                Tool(image: UIImage.heifToPng, title: "HEIF to PNG", fromFormat: .heif, toFormat: .png, action: .convert, type: .imageToImage),
                Tool(image: UIImage.tiffToPng, title: "TIFF to PNG", fromFormat: .tiff, toFormat: .png, action: .convert, type: .imageToImage),
                Tool(image: UIImage.gifToPng, title: "GIF to PNG", fromFormat: .gif, toFormat: .png, action: .convert, type: .imageToImage),
                Tool(image: UIImage.webpToPng, title: "WebP to PNG", fromFormat: .webp, toFormat: .png, action: .convert, type: .imageToImage),
                Tool(image: UIImage.pdfToPng, title: "PDF to PNG", fromFormat: .pdf, toFormat: .png, action: .convert, type: .pdfToImage)
            ]
//        case .webp:
//            tools = [
//                Tool(image: UIImage.pngToWebp, title: "PNG to WebP", fromFormat: .png, toFormat: .webp, action: .convert, type: .imageToImage),
//                Tool(image: UIImage.jpgToWebp, title: "JPG to WebP", fromFormat: .jpg, toFormat: .webp, action: .convert, type: .imageToImage)
//            ]
        case .pdf:
            tools = [
                Tool(image: UIImage.imgToPdf, title: "Image to PDF", fromFormat: .img, toFormat: .pdf, action: .convert, type: .imageToPDF),
                Tool(image: UIImage.jpgToPdf, title: "JPG to PDF", fromFormat: .jpg, toFormat: .pdf, action: .convert, type: .imageToPDF),
                Tool(image: UIImage.pngToPdf, title: "PNG to PDF", fromFormat: .png, toFormat: .pdf, action: .convert, type: .imageToPDF),
                Tool(image: UIImage.gifToPdf, title: "GIF to PDF", fromFormat: .gif, toFormat: .pdf, action: .convert, type: .imageToPDF),
                Tool(image: UIImage.tiffToPdf, title: "TIFF to PDF", fromFormat: .tiff, toFormat: .pdf, action: .convert, type: .imageToPDF),
                Tool(image: UIImage.webpToPdf, title: "WebP to PDF", fromFormat: .webp, toFormat: .pdf, action: .convert, type: .imageToPDF),
                Tool(image: UIImage.heicToPdf, title: "HEIC to PDF", fromFormat: .heic, toFormat: .pdf, action: .convert, type: .imageToPDF),
                Tool(image: UIImage.heifToPdf, title: "HEIF to PDF", fromFormat: .heif, toFormat: .pdf, action: .convert, type: .imageToPDF)
            ]
        case .other:
            tools = [
                Tool(image: UIImage.resizeIcon, title: "Resize Image", fromFormat: .img, toFormat: .jpg, action: .resize, type: .imageToImage),
                Tool(image: UIImage.watermarkIcon, title: "Watermark", fromFormat: .img, toFormat: .jpg, action: .watermark, type: .imageToImage),
                Tool(image: UIImage.rotateIcon, title: "Rotate Image", fromFormat: .img, toFormat: .jpg, action: .rotate, type: .imageToImage),
                Tool(image: UIImage.compressIcon, title: "Compress", fromFormat: .img, toFormat: .jpg, action: .compress, type: .imageToImage),
                Tool(image: UIImage.convertToZipIcon, title: "Convert to Zip", fromFormat: .img, toFormat: .zip, action: .zip, type: .imageToZip),
                Tool(image: UIImage.cropIcon, title: "Crop Image", fromFormat: .img, toFormat: .jpg, action: .crop, type: .imageToImage),
                Tool(image: UIImage.extractTextIcon, title: "Extract Text", fromFormat: .img, toFormat: .txt, action: .extractText, type: .imageToText)
            ]
        }
        
        return tools
    }
}

class ToolManager {
    var toolsByCategory: [ToolType: [Tool]] = [:]
    
    init() {
        ToolType.allCases.forEach { category in
            toolsByCategory[category] = category.tools
        }
    }
}
