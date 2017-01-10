//
//  PPBatchManager.swift
//  PhonePe
//
//  Created by Jatin Arora on 09/01/17.
//  Copyright © 2017 PhonePe Internet Private Limited. All rights reserved.
//

import Foundation
import YapDatabase

class PPBatchManager {
    
    typealias NetworkCallCompletion = (Data?, URLResponse?, Error?, [String]) -> Void
    
    private let sizeStrategy: PPSizeBatchingStrategy
    private let timeStrategy: PPTimeBatchingStrategy
    private let ingestionURL: URL
    private var httpHeaders: [String: String]
    private let batchingQueue = DispatchQueue(label: "batching.library.queue")
    private var isUploadingEvents = false
    private let database: YapDatabase
    
    
    var debugEnabled = false
    
    private var databasePath: String = {
    
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let eventsPath = (documentsPath as NSString).appendingPathComponent("Event Batching")
        let finalPath = (eventsPath as NSString).appendingPathComponent("EventsDB.sqlite")
        
        return finalPath
        
    }()
    
    
    init(sizeStrategy: PPSizeBatchingStrategy,  timeStrategy: PPTimeBatchingStrategy, ingestionURL: URL, httpHeaders: [String: String]) {
        self.sizeStrategy = sizeStrategy
        self.timeStrategy = timeStrategy
        self.ingestionURL = ingestionURL
        self.httpHeaders = httpHeaders
        self.database = YapDatabase(path: databasePath)
    }
    
    
    func addToBatch(event: BatchSerializable) {
        
        batchingQueue.async {

            //1. Assign eventID (UUID)
            //2. Store in the YapDB
            
            let eventID = UUID().uuidString
            let connection = self.database.newConnection()
            
            connection.asyncReadWrite({ (transaction) in
                
                transaction.setObject(event.dictionaryRepresentation(), forKey: eventID, inCollection: nil)
                
            }, completionQueue: self.batchingQueue, completionBlock: { 
                
                self.flush(forced: false)
                
            })
            
        }
        
    }
    
    func flush(forced: Bool) {
        
        batchingQueue.async {
        
            //Check if the flushing is forced, events > 0
            if forced {
                self.ingestBatch(completion: self.handleBatchingResponse)
            } else {
                
                //Check for strategy based conditions here and then ingest
                
                self.ingestBatch(completion: self.handleBatchingResponse)
                
            }
        
        }
        
    }
    
    func changeHTTPHeadersTo(_ newParams: [String: String]) {
        
        batchingQueue.async {
            self.httpHeaders = newParams
        }
        
    }
    
    private func ingestBatch(completion: @escaping NetworkCallCompletion) {
        
        
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
            
            self.sendBatchWith(objects: allObjects, forKeys: allKeys, completion: completion)
        })
            
        
    }
    
    private func sendBatchWith(objects: [Any], forKeys keys: [String], completion: @escaping NetworkCallCompletion) {
        
        self.batchingQueue.async {
            
            //2. Upload the events
            
            let session = URLSession.shared
            var request = URLRequest(url: self.ingestionURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            //Change this to actual body based on the batch of events
            do {
                
                request.httpBody = try JSONSerialization.data(withJSONObject: objects, options: .prettyPrinted)
                request.allHTTPHeaderFields = self.httpHeaders
                
                let _ = session.dataTask(with: request) { (data, response, error) in
                    completion(data, response, error, keys)
                }
                
            } catch {
                assert(false, "Failed to serialise data from the yapDB")
                self.isUploadingEvents = false
            }
            
        }
        
    }
    
    private func handleBatchingResponse(data: Data?, response: URLResponse?, error: Error?, keys: [String]) {
        
        batchingQueue.async {
        
            //Handle response 
            //If the response is success then delete the corresponding events from YapDB
            
            if let response = response as? HTTPURLResponse {
                
                if response.statusCode == 200 {
                    
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
                
            } else {
                
                self.isUploadingEvents = false
                
            }
            
        }
        
    }
    
    private func removeEventsWithIds(_ ids: [String], completion: @escaping (Void) -> Void) {
        
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
    
    private func newDBConnection() -> YapDatabaseConnection {
        return self.database.newConnection()
    }
}
