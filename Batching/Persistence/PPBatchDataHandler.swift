//
//  PPBatchDataHandler.swift
//  Batching
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData

final class PPBatchDataHandler {
    
    private let dataStoreController: PPBatchDataStoreController
    
    init?(dbName: String) {
        guard let storeController = PPBatchDataStoreController(dbName: dbName) else {
            return nil
        }
        
        dataStoreController = storeController
    }
    
    func save(event: NSObject, id: String, timestamp: Double) {
        
        guard let moc = dataStoreController.managedObjectContext else {
            assert(false, "moc not initialized")
            return
        }
        
        moc.performAndWait {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: event) as NSData
            
            if let _ = Event.insertEventFor(data: data, id: id, timestamp: timestamp, in: moc) {
                do {
                    try moc.save()
                } catch {
                    assert(false, "Save to the DB failed with error = \(error)")
                }
            }
            
        }
        
    }
    
    func deleteEventsWith(ids: Set<String>) {
        
        guard let moc = dataStoreController.managedObjectContext else {
            assert(false, "moc not initialized")
            return
        }
        
        moc.performAndWait {
            
            
            if #available(iOS 9, *) {
                
                let fetch = PPBatchDataHandler.fetchRequestForEventWith(ids: ids)
                
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
                batchDeleteRequest.resultType = NSBatchDeleteRequestResultType.resultTypeObjectIDs
                
                do {
                    let result = try moc.execute(batchDeleteRequest) as? NSBatchDeleteResult
                    
                    //Update the moc about the change
                    if let objectIDArray = result?.result as? [NSManagedObjectID] {
                        let changes = [NSDeletedObjectsKey : objectIDArray]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [moc])
                    }
                    
                } catch {
                    assert(false, "Failed to delete objects in batches with error : \(error)")
                }
                
            } else {
            
                let request = PPBatchDataHandler.fetchRequestForEventWith(ids: ids)
                
                do {
                    
                    if let events = try moc.fetch(request) as? [Event] {
                        
                        for event in events {
                            moc.delete(event)
                        }
                        
                        try moc.save()
                    }
                    
                } catch {
                    assert(false, "Failed to delete objects with error: \(error)")
                }
                
            }
            
        }
        
    }
    
    func fetchEventDatas(count: Int) -> [Any]? {
        
        var events: [Event]? = nil
        
        guard let moc = dataStoreController.managedObjectContext else {
            assert(false, "moc not initialized")
            return events
        }
        
        moc.performAndWait {
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
            request.fetchLimit = count
            
            do {
                events = try moc.fetch(request) as? [Event]
            } catch {
                assert(false, "Failed to fetch events with error = \(error)")
            }
        }
        
        if let events = events {
        
            var eventDatas = [Any]()
            for event in events {
                
                if let unwrappedData = event.data, let finalData = NSKeyedUnarchiver.unarchiveObject(with: unwrappedData as Data) {
                    eventDatas.append(finalData)
                }
                
            }
            
            return eventDatas
        }
        
        
        return nil
    }
    
    static func fetchRequestForEventWith(ids: Set<String>) -> NSFetchRequest<NSFetchRequestResult> {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
        fetch.predicate = NSPredicate(format: "ids IN %@", ids)
        
        return fetch
    }
}