import Foundation

class HistoryRepository {
    static let shared = HistoryRepository()
    private let service: CoreDataService
    init() {
        let stack = CoreDataStack(modelName: "ImageConverter", isCloudKitEnabled: false)
        service = .init(coreDataStack: stack)
    }
    
    func fetchAllHistory() throws -> [CDHistory] {
        try service.fetchAll(CDHistory.self).reversed()
    }
    
    func createNewHistory(with historyItem: History) throws -> CDHistory {
        let history = service.create(CDHistory.self)
        history.id = historyItem.id
        history.title = historyItem.title
        history.date = historyItem.date
        history.size = Int32(historyItem.size)
        history.type = historyItem.toType.rawValue
        history.action = historyItem.action.rawValue
        history.category = historyItem.category.rawValue
        
        do {
            try service.saveContext()
            return history
        } catch {
            throw error
        }
    }
    
    func deleteHistory(_ history: CDHistory) throws {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = history.title
        let fileURL = directory.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ File deleted at: \(fileURL)")
        } catch {
            print("❌ Error deleting file: \(error.localizedDescription)")
        }
        try service.delete(history)
    }
    
    func deleteAllHistory() throws {
        try service.deleteAllObjects(of: CDHistory.self)
    }
    
    func updateHistory() throws {
        try service.saveContext()
    }
    
    func updateHistoryTitle(_ history: CDHistory, newTitle: String) throws {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = history.title
        let fileURL = directory.appendingPathComponent(fileName)
        
        let result = try service.fetchById(CDHistory.self, id: history.objectID)
        if let historyItem = result {
            historyItem.title = newTitle
            try service.saveContext()
            
            let newFileURL = directory.appendingPathComponent(newTitle)
            try FileManager.default.moveItem(at: fileURL, to: newFileURL)
            print("✅ File moved to: \(newFileURL)")
        }
    }
}
