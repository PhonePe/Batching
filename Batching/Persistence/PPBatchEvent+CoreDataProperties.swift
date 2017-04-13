//
//  PPBatchEvent+CoreDataProperties.swift
//  Batching
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation
import CoreData


extension PPBatchEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PPBatchEvent> {
        return NSFetchRequest<PPBatchEvent>(entityName: "PPBatchEvent")
    }

    @NSManaged public var data: NSObject?
    @NSManaged public var id: String?
    @NSManaged public var timestamp: Double

}
