//
//  PPBatchDataStoreController.swift
//  Batching
//
//  Created by Jatin Arora on 12/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData

class PPBatchDataStoreController {

    private var _managedObjectContext: NSManagedObjectContext
    private var storeCoordinator: NSPersistentStoreCoordinator
    private var managedObjectModel: NSManagedObjectModel
    private var queue: DispatchQueue
    
    var managedObjectContext: NSManagedObjectContext? {
        
        guard _managedObjectContext.persistentStoreCoordinator != nil, storeCoordinator.persistentStores.isEmpty == false else {
            return nil
        }
        
        return _managedObjectContext
    }
    
    init?(dbName: String) {
        
        //Setup model
        
        guard let modelUrl = Bundle.batching_frameworkBundle().url(forResource: "BatchingDataModel", withExtension: "momd") else {
            assert(false, "Could not find the model file")
            return nil
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            assert(false, "Could not create the model")
            return nil
        }
        
        managedObjectModel = model
        
        
        //Setup store coordinator
        
        storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        
        //Setup queue
        
        queue = DispatchQueue(label: "BatchingSerialDataQueue")
        

        //Setup moc
        
        _managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        _managedObjectContext.persistentStoreCoordinator = storeCoordinator

        
        //Setup store
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption : true,
            NSInferMappingModelAutomaticallyOption : true
        ]
        
        let storeUrl = URL(fileURLWithPath: PPBatchDataStoreController.databasePath(dbName: dbName))
        
        queue.async {
        
            do {
                try self.storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
            } catch {
                assert(false, "Could not add store to coordinator")
            }
            
        }
        
    }
    
    
    func inContext(callback: @escaping (NSManagedObjectContext?) -> Void) {
        
        queue.async {
            
            guard let context = self.managedObjectContext else {
                callback(nil)
                return
            }
            
            callback(context)
        }
        
    }
    
    fileprivate static func databasePath(dbName: String) -> String {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let eventsPath = (documentsPath as NSString).appendingPathComponent("Event Batching")
        
        PPBatchUtils.createDirectoryIfNotExists(at: eventsPath)
        
        let finalPath = (eventsPath as NSString).appendingPathComponent("\(dbName).sqlite")
        
        return finalPath
        
    }
    
}


extension Bundle {
    
    static func batching_frameworkBundle() -> Bundle {
        
        let bundle = Bundle(for: PPBatchDataStoreController.self)
        if let path = bundle.path(forResource: "Batching", ofType: "bundle") {
            return Bundle(path: path)!
        }
        else {
            return bundle
        }
    }
}
