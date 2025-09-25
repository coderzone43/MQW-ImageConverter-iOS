//
//  CDHistory+CoreDataClass.swift
//  Image Converter
//
//  Created by Macbook Pro on 15/09/2025.
//
//

import Foundation
import CoreData

@objc(CDHistory)
public class CDHistory: NSManagedObject, Identifiable {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDHistory> {
        return NSFetchRequest<CDHistory>(entityName: "CDHistory")
    }

    @NSManaged public var type: String
    @NSManaged public var category: String
    @NSManaged public var action: String
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var size: Int32
    @NSManaged public var date: Date
}
