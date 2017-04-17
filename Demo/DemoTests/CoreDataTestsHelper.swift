//
//  CoreDataTestsHelper.swift
//  Demo
//
//  Created by Jatin Arora on 17/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData

final class CoreDataTestsHelper {

    static func setupInMemoryManagedObjectContext() -> NSManagedObjectContext {
    
        let model = NSManagedObjectModel.mergedModel(from: Bundle.allBundles)
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model!)
        
        do {
            try psc.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Error in creating an in memory persisten store = \(error)")
        }
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = psc
        
        return moc
    }
    
}
