//
//  Event+CoreDataProperties.swift
//  Batching
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData


extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var data: NSData?
    @NSManaged public var id: String?
    @NSManaged public var timestamp: Double

}
