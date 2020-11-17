//
//  PersistentContainer.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import Foundation
import CoreData

class PersistentContainer: NSPersistentContainer {
    private static let lastCleanedKey = "lastCleaned"

    static let shared: PersistentContainer = {
        
        let container = PersistentContainer(name: "Atom_Movie_Listing")
        container.loadPersistentStores { (desc, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
            
            print("Successfully loaded persistent store at: \(desc.url?.description ?? "nil")")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        
        return container
    }()
    
    var lastCleaned: Date? {
        get {
            return UserDefaults.standard.object(forKey: PersistentContainer.lastCleanedKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PersistentContainer.lastCleanedKey)
        }
    }
    
    override func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = super.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        return backgroundContext
    }
}


