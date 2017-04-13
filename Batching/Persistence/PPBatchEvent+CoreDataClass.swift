//
//  PPBatchEvent+CoreDataClass.swift
//  Batching
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData

@objc(PPBatchEvent)
public class PPBatchEvent: NSManagedObject {

    static func insertEventFor(data: NSObject, id: String, timestamp: Double, in moc: NSManagedObjectContext) -> PPBatchEvent? {
        
        guard let newEvent = NSEntityDescription.insertNewObject(forEntityName: "PPBatchEvent", into: moc) as? PPBatchEvent else {
            return nil
        }
        
        newEvent.data = data
        newEvent.id = id
        newEvent.timestamp = timestamp
        
        return newEvent
    }

    
}
