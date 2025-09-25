import UIKit
import Vision

class OCRManager {
    func extractText(from imageURLs: [URL], cancellationToken: CancellationToken, progressHandler: @escaping (Double) -> Void, completion: @escaping ([String], Bool) -> Void) {
        var results: [String] = Array(repeating: "", count: imageURLs.count)
        let total = imageURLs.count
        var completed = 0
        let lock = NSLock()
        
        let dispatchGroup = DispatchGroup()
        
        for (index, url) in imageURLs.enumerated() {
            guard !cancellationToken.cancelled() else {
                DispatchQueue.main.async {
                    completion([], true)
                }
                return
            }
            
            dispatchGroup.enter()
            
            if let image = UIImage(contentsOfFile: url.path),
               let cgImage = image.cgImage {
                
                let request = VNRecognizeTextRequest { (request, error) in
                    defer {
                        lock.lock()
                        completed += 1
                        let progress = Double(completed) / Double(total)
                        lock.unlock()
                        
                        DispatchQueue.main.async {
                            if !cancellationToken.cancelled() {
                                progressHandler(progress)
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    guard !cancellationToken.cancelled() else { return }
                    
                    if let observations = request.results as? [VNRecognizedTextObservation] {
                        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                        results[index] = text
                    } else if let error = error {
                        print("OCR error for \(url.lastPathComponent): \(error)")
                    }
                }
                
                request.recognitionLanguages = ["en-US"]
                request.usesLanguageCorrection = true
                
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        guard !cancellationToken.cancelled() else {
                            dispatchGroup.leave()
                            return
                        }
                        try requestHandler.perform([request])
                    } catch {
                        print("Error performing OCR for \(url.lastPathComponent): \(error)")
                        dispatchGroup.leave()
                    }
                }
            } else {
                lock.lock()
                completed += 1
                lock.unlock()
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(results, cancellationToken.cancelled())
        }
    }
}
