//
//  PPBatchManager.swift
//  PhonePe
//
//  Created by Jatin Arora on 09/01/17.
//  Copyright © 2017 PhonePe Internet Private Limited. All rights reserved.
//

import Foundation
import YapDatabase

typealias EventIngestionCompletion = (Bool, Error?, [String]) -> Void

public protocol PPBatchManagerDelegate: class {
    func batchManagerShouldIngestBatch(_ manager: PPBatchManager, batch: [Any], completion: @escaping (Bool, Error?) -> Void)
}

public class PPBatchManager {
    
    fileprivate let sizeStrategy: PPSizeBatchingStrategy
    fileprivate let timeStrategy: PPTimeBatchingStrategy
    fileprivate let batchingQueue = DispatchQueue(label: "batching.library.queue")
    fileprivate var isUploadingEvents = false
    fileprivate let database: YapDatabase
    
    public weak var delegate: PPBatchManagerDelegate?
    
    public var debugEnabled = false
    
    fileprivate var databasePath: String = {
    
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let eventsPath = (documentsPath as NSString).appendingPathComponent("Event Batching")
        
        if FileManager.default.fileExists(atPath: eventsPath) == false {
        
            do {
                try FileManager.default.createDirectory(atPath: eventsPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                assert(false, "Unable to create DB directory for Batching Pod")
            }
            
        }
        
        
        let finalPath = (documentsPath as NSString).appendingPathComponent("EventsDB.sqlite")
        
        return finalPath
        
    }()
    
    
    public init(sizeStrategy: PPSizeBatchingStrategy,  timeStrategy: PPTimeBatchingStrategy) {
        self.sizeStrategy = sizeStrategy
        self.timeStrategy = timeStrategy
        self.database = YapDatabase(path: databasePath, options: nil)
    }
    
    
    public func addToBatch(_ event: NSObject) {
        
        batchingQueue.async {

            //1. Assign eventID (UUID)
            //2. Store in the YapDB
            
            let eventID = UUID().uuidString
            let connection = self.database.newConnection()
            
            connection.asyncReadWrite({ (transaction) in
                
                transaction.setObject(event, forKey: eventID, inCollection: nil)
                
            }, completionQueue: self.batchingQueue, completionBlock: { 
                
                self.flush(false)
                
            })
            
        }
        
    }
    
    public func flush(_ forced: Bool) {
        
        batchingQueue.async {
        
            let connection = self.database.newConnection()
            var count = 0
            
            connection.read({ (transaction) in
                count = transaction.allKeys(inCollection: nil).count
            })

            //Check the strategies and count of events here
            
            if (forced || self.isBatchReady(eventCount: Int64(count))) && count > 0 {
                self.ingestBatch(self.handleBatchingResponse)
            }
        
        }
        
    }
    
    fileprivate func isBatchReady(eventCount: Int64) -> Bool {
    
        if eventCount >= self.sizeStrategy.eventsBeforeIngestion {
            return true
        }
        
        let lastSuccessfulIngestionTime = UserDefaults.standard.double(forKey: PPBatchUserDefaults.lastSuccessfulIngestionTime)
        
        if NSDate().timeIntervalSince1970 - lastSuccessfulIngestionTime >= self.timeStrategy.timeBeforeIngestion {
            return true
        }
        
        return false
    }
    
    fileprivate func ingestBatch(_ completion: @escaping EventIngestionCompletion) {
        
        
        self.isUploadingEvents = true
        
        //1. Get events from YapDB
        
        let connection = self.newDBConnection()
        
        connection.read({ (transaction) in
            
            var allObjects = [Any]()
            var allKeys = [String]()
            
            transaction.enumerateKeysAndObjects(inCollection: nil, using: { (key, object, _) in                
                allObjects.append(object)
                allKeys.append(key)
            })
            
            self.sendBatchWith(allObjects, forKeys: allKeys, completion: completion)
        })
            
        
    }
    
    fileprivate func sendBatchWith(_ objects: [Any], forKeys keys: [String], completion: @escaping EventIngestionCompletion) {
        
        self.batchingQueue.async {
            
            self.delegate?.batchManagerShouldIngestBatch(self, batch: objects, completion: { (success, error) in
                
                self.batchingQueue.async {
                    self.isUploadingEvents = false
                    completion(success, error, keys)
                }
                
            })
            
        }
        
    }
    
    fileprivate func handleBatchingResponse(success: Bool, error: Error?, keys: [String]) {
        
        batchingQueue.async {
        
            //Handle response 
            //If the response is success then delete the corresponding events from YapDB
            
            
            if error == nil && success {
                
                UserDefaults.standard.set(NSDate().timeIntervalSince1970, forKey: PPBatchUserDefaults.lastSuccessfulIngestionTime)
                UserDefaults.standard.synchronize()
                
                self.removeEventsWithIds(keys, completion: {
                    
                    self.isUploadingEvents = false
                    
                })
                
                //Remove all objects for corresponding keys from YapDB
                
                let connection = self.newDBConnection()
                
                connection.asyncReadWrite({ (transaction) in
                    
                    for key in keys {
                        transaction.removeObject(forKey: key, inCollection: nil)
                    }
                    
                }, completionQueue: self.batchingQueue, completionBlock: {
                    self.isUploadingEvents = false
                })
                
                
                
            } else {
                
                self.isUploadingEvents = false
                
            }
            
        }
        
    }
    
    fileprivate func removeEventsWithIds(_ ids: [String], completion: @escaping (Void) -> Void) {
        
        batchingQueue.async {
        
            //Remove all objects for corresponding keys from YapDB
            
            let connection = self.newDBConnection()
            
            connection.asyncReadWrite({ (transaction) in
                
                for key in ids {
                    transaction.removeObject(forKey: key, inCollection: nil)
                }
                
            }, completionQueue: self.batchingQueue, completionBlock: {
                
                completion()
                
            })
            
        }
        
        
    }
    
    fileprivate func newDBConnection() -> YapDatabaseConnection {
        return self.database.newConnection()
    }
}
