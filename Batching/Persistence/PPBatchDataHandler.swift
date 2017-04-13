//
//  PPBatchDataHandler.swift
//  Batching
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData

struct PPEventDataFetchResult {
    let datas: [Any]?
    let ids: [String]?
}

final class PPBatchDataHandler {
    
    private let dataStoreController: PPBatchDataStoreController
    
    init?(dbName: String) {
        guard let storeController = PPBatchDataStoreController(dbName: dbName) else {
            return nil
        }
        
        dataStoreController = storeController
    }
    
    func save(event: NSObject, id: String, timestamp: Double) {
        
        dataStoreController.inContext { (moc) in
            
            guard let moc = moc else {
                assert(false, "moc not initialized")
                return
            }

            moc.performAndWait {
                
                if let _ = Event.insertEventFor(data: event, id: id, timestamp: timestamp, in: moc) {
                    do {
                        try moc.save()
                    } catch {
                        assert(false, "Save to the DB failed with error = \(error)")
                    }
                }
                
            }
            
        }
        
    }
    
    func deleteEventsWith(ids: Set<String>) {
        
        dataStoreController.inContext { (moc) in
        
            guard let moc = moc else {
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
        
        
    }
    
    func fetchEventDatas(count: Int) -> PPEventDataFetchResult {
        
        var eventDatas = [Any]()
        var ids = [String]()
        
        dataStoreController.inContext { (moc) in
        
            guard let moc = moc else {
                assert(false, "moc not initialized")
                return
            }
            
            moc.performAndWait {
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
                request.fetchLimit = count
                
                do {
                    
                    if let events = try moc.fetch(request) as? [Event] {
                        
                        for event in events {
                            
                            if let unwrappedData = event.data {
                                eventDatas.append(unwrappedData)
                            }
                            
                            if let id = event.id {
                                ids.append(id)
                            }
                            
                        }
                        
                    }
                    
                } catch {
                    assert(false, "Failed to fetch events with error = \(error)")
                }
                
            }
            
        }
        
        if eventDatas.count == 0 || ids.count == 0 {
            return PPEventDataFetchResult(datas: nil, ids: nil)
        }
        
        return PPEventDataFetchResult(datas: eventDatas, ids: ids)
        
    }
    
    func countOfEvents() -> Int {
        
        var count = 0
        
        dataStoreController.inContext { (moc) in
        
            guard let moc = moc else {
                assert(false, "moc not initialized")
                return
            }
            
            moc.performAndWait {
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
                
                do {
                    count = try moc.count(for: request)
                } catch {
                    assert(false, "Could not fetch count error: \(error)")
                }
                
            }
            
        }
        
        return count
    }
    
    static func fetchRequestForEventWith(ids: Set<String>) -> NSFetchRequest<NSFetchRequestResult> {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
        fetch.predicate = NSPredicate(format: "id IN %@", ids)
        
        return fetch
    }
}
