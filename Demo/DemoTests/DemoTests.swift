//
//  DemoTests.swift
//  DemoTests
//
//  Created by Jatin Arora on 17/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import XCTest
import CoreData
@testable import Batching
@testable import Demo

class DemoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSavingEvent() {
        
        let moc = CoreDataTestsHelper.setupInMemoryManagedObjectContext()
        
        let testEvent = TestEvent(name: "Test 1")
        PPBatchDataHandler.save(event: testEvent, id: UUID().uuidString, timestamp: Date().timeIntervalSince1970, moc: moc)
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PPBatchEvent")
        var count = 0
        
        do {
            count = try moc.count(for: fetchRequest)
        } catch {
            XCTAssert(false, "Failed to fetch count from DB")
        }
        
        
        XCTAssert(count == 1, "Event not inserted in the DB")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
