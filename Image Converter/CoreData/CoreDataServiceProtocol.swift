import Foundation
import CoreData

protocol CoreDataServiceProtocol {
    var coreDataStack: CoreDataStack {
        get
    }
    func fetchAll<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]?
    ) throws -> [T]
    
    func fetchById<T: NSManagedObject>(
        _ entityType: T.Type,
        id: NSManagedObjectID
    ) throws -> T?
    
    func create<T: NSManagedObject>(
        _ entityType: T.Type
    ) -> T
    
    func createTemporary<T: NSManagedObject>(
        _ entityType: T.Type
    ) -> T
    func commitTemporary<T: NSManagedObject>(
        _ temporaryObject: T
    ) throws
    func isTemporary(
        _ object: NSManagedObject
    ) -> Bool
    func delete(
        _ object: NSManagedObject
    ) throws
    func deleteAllObjects<T: NSManagedObject>(
        of entityType: T.Type
    ) throws
    func saveContext() throws
}

class CoreDataService: CoreDataServiceProtocol {
    var coreDataStack: CoreDataStack
    
    private var context: NSManagedObjectContext {
        coreDataStack.context
    }
    
    init(
        coreDataStack: CoreDataStack
    ) {
        self.coreDataStack = coreDataStack
    }
    
    func fetchAll<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) throws -> [T] {
        let request = T.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return try context
            .fetch(
                request
            ) as! [T]
    }
    
    func fetchById<T: NSManagedObject>(
        _ entityType: T.Type,
        id: NSManagedObjectID
    ) throws -> T? {
        return try context
            .existingObject(
                with: id
            ) as? T
    }
    
    // Existing create method (inserts into context immediately)
    func create<T: NSManagedObject>(
        _ entityType: T.Type
    ) -> T {
        return T(
            context: context
        )
    }
    
    // New method to create a temporary entity (not inserted into context)
    func createTemporary<T: NSManagedObject>(
        _ entityType: T.Type
    ) -> T {
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: String(
                describing: entityType
            ),
            in: context
        ) else {
            fatalError(
                "Entity \(entityType) not found in model"
            )
        }
        let temporaryObject = T(
            entity: entityDescription,
            insertInto: nil
        )
        return temporaryObject
    }
    
    // New method to commit a temporary entity to the context
    func commitTemporary<T: NSManagedObject>(
        _ temporaryObject: T
    ) throws {
        context
            .insert(
                temporaryObject
            )
        try saveContext()
    }
    
    func delete(
        _ object: NSManagedObject
    ) throws {
        context
            .delete(
                object
            )
        try saveContext()
    }
    
    func deleteAllObjects<T: NSManagedObject>(
        of entityType: T.Type
    ) throws {
        let entityName = String(
            describing: entityType
        )
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: entityName
        )
        
        let batchDeleteRequest = NSBatchDeleteRequest(
            fetchRequest: fetchRequest
        )
        try context
            .execute(
                batchDeleteRequest
            )
        
        try saveContext()
    }
    
    func saveContext() throws {
        if context.hasChanges {
            try context
                .save()
        }
    }
    
    // New method to check if an object is temporary
    func isTemporary(
        _ object: NSManagedObject
    ) -> Bool {
        return object.managedObjectContext == nil
    }
}
