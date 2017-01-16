//
//  DataStoreController.swift
//  Batching
//
//  Created by Jatin Arora on 16/01/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData


class DataStoreController {
    
    
    private var _managedObjectContext: NSManagedObjectContext
    private var storeCoordinator: NSPersistentStoreCoordinator
    private var managedObjectModel: NSManagedObjectModel
    private var queue: DispatchQueue
    var error: Error?
    
    static let sharedController = DataStoreController()
    
    var managedObjectContext: NSManagedObjectContext? {
        
        guard _managedObjectContext.persistentStoreCoordinator != nil else {
            return nil
        }
        
        if storeCoordinator.persistentStores.isEmpty {
            return nil
        }
        
        return _managedObjectContext
    }
    
    init() {
        
        let modelUrl = Bundle.main.url(forResource: "DataModel", withExtension: "momd")
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docUrl = urls[urls.endIndex - 1]
        let storeUrl = docUrl.appendingPathComponent("DataModel.sqlite")
        
        //Create model
        
        guard let modelAtUrl = NSManagedObjectModel(contentsOf: modelUrl!) else {
            fatalError("Error in initialising managed object model")
        }
        
        managedObjectModel = modelAtUrl
        
        //Create PSC
        
        storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        _managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        _managedObjectContext.persistentStoreCoordinator = storeCoordinator
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption : true,
            NSInferMappingModelAutomaticallyOption : true
        ]
        
        queue = DispatchQueue(label: "localSerialDataQueue")
        
        queue.async {
            
            //Add stores to the PSC
            
            do {
                try self.storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
            } catch {
                fatalError("Error in adding stores to psc with error = \(error)")
            }
            
        }
        
    }
    
    
    func inContext(callback: @escaping (NSManagedObjectContext?) -> Void) {
        
        queue.async {
            
            guard let context = self.managedObjectContext else {
                callback(nil)
                return
            }
            
            return callback(context)
        }
        
    }
    
}
