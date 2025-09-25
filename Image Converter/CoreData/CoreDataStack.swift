import Foundation
import CoreData

class CoreDataStack {
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }

    init(modelName: String, isCloudKitEnabled: Bool) {
        var container: NSPersistentContainer = NSPersistentContainer(name: modelName)
        if isCloudKitEnabled {
            container = NSPersistentCloudKitContainer(name: modelName)
        }
        persistentContainer = container
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                print("Failed to load persistent stores: \(error)")
            }
        }
    }
}
