import Foundation

class CompressionManager {
    static let shared = CompressionManager()
    private init() {}
    
    private var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func reset() {
        isCancelled = false
    }
    
    var cancelled: Bool {
        return isCancelled
    }
}
