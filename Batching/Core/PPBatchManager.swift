//
//  PPBatchManager.swift
//  PhonePe
//
//  Created by Jatin Arora on 09/01/17.
//  Copyright © 2017 PhonePe Internet Private Limited. All rights reserved.
//

import Foundation

typealias EventIngestionCompletion = (Bool, Error?, [String]) -> Void

public protocol PPBatchManagerDelegate: class {
    func batchManagerShouldIngestBatch(_ manager: PPBatchManager, batch: [Any], completion: @escaping (Bool, Error?) -> Void)
}

public class PPBatchManager {
    
    fileprivate let sizeStrategy: PPSizeBatchingStrategy
    fileprivate let timeStrategy: PPTimeBatchingStrategy
    fileprivate let batchingQueue = DispatchQueue(label: "batching.library.queue")
    fileprivate var isUploadingEvents = false
    fileprivate var timer: Timer? = nil
    fileprivate let dbName: String
    fileprivate let dataHandler: PPBatchDataHandler?
    
    public weak var delegate: PPBatchManagerDelegate?
    
    public var debugEnabled = false
    
    public init(sizeStrategy: PPSizeBatchingStrategy,  timeStrategy: PPTimeBatchingStrategy, dbName: String) {
        self.sizeStrategy = sizeStrategy
        self.timeStrategy = timeStrategy
        self.dbName = dbName
        
        self.dataHandler = PPBatchDataHandler(dbName: dbName)
        
        scheduleTimer()
        
        //Flush when the class is initialised, this is to make sure that if app gets killed during flushing we retry immediately after launch
        flush(false)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func addToBatch(_ event: NSObject, timestamp: Double) {
        
        batchingQueue.async {
            
            //1. Assign eventID (UUID)
            //2. Store in the DB
            
            let eventID = UUID().uuidString
            self.dataHandler?.save(event: event, id: eventID, timestamp: timestamp)
            self.flush(false)
            
        }
        
    }
    
    public func flush(_ forced: Bool) {
        
        batchingQueue.async {
        
            let count = self.dataHandler?.countOfEvents() ?? 0

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
        
        return false
    }
    
    fileprivate func ingestBatch(_ completion: @escaping EventIngestionCompletion) {
        
        //We should upload next set of events, once the current batch has finished processing
        if self.isUploadingEvents {
            return
        }
        
        self.isUploadingEvents = true
        
        //1. Get events from DB
        
        let result = self.dataHandler?.fetchEventDatas(count: Int(self.sizeStrategy.eventsBeforeIngestion))
        
        if let eventDatas = result?.datas, let ids = result?.ids {
            self.sendBatchWith(eventDatas, forKeys: ids, completion: completion)
        }
        
    }
    
    fileprivate func sendBatchWith(_ objects: [Any], forKeys keys: [String], completion: @escaping EventIngestionCompletion) {
        
        self.batchingQueue.async {
            
            self.delegate?.batchManagerShouldIngestBatch(self, batch: objects, completion: { (success, error) in
                
                self.batchingQueue.async {
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
                                
                self.removeEventsWithIds(keys, completion: {
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
            self.dataHandler?.deleteEventsWith(ids: Set(ids))
            completion()
            
        }
        
        
    }
        
    fileprivate func scheduleTimer() {
        
        guard timer == nil else { return }
        
        //Weakly wrapping self to avoid unnecessarily retaining self by Timer
        
        let weakSelf = PPBatchManagerWrapper(batchManager: self)
        timer = Timer.scheduledTimer(timeInterval: self.timeStrategy.durationBeforeIngestion, target: weakSelf, selector: #selector(PPBatchManagerWrapper.timerFired), userInfo: nil, repeats: true)
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .commonModes)
        }
        
    }
    
    //This is a wrapper to make sure self is deinitialised properly
    final private class PPBatchManagerWrapper {
        
        weak var batchManager: PPBatchManager?
        
        init(batchManager: PPBatchManager) {
            self.batchManager = batchManager
        }
        
        @objc func timerFired() {
            //Force push the events once timer is fired
            batchManager?.flush(true)
        }
        
    }
    
}
