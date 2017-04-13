//
//  Event+CoreDataClass.swift
//  Batching
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData

@objc(Event)
public class Event: NSManagedObject {

    static func insertEventFor(data: NSData, id: String, timestamp: Double, in moc: NSManagedObjectContext) -> Event? {
        
        guard let newEvent = NSEntityDescription.insertNewObject(forEntityName: "Event", into: moc) as? Event else {
            return nil
        }
        
        newEvent.data = data
        newEvent.id = id
        newEvent.timestamp = timestamp
        
        return newEvent
    }
    
}
