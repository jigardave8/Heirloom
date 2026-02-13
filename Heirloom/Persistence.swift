//
//  Persistence.swift
//  Heirloom
//
//  Created by BitDegree on 13/02/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Heirloom") // Ensure this matches your .xcdatamodeld filename
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // Improve performance by automatically merging changes
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
