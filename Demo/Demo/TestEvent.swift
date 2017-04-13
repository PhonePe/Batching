//
//  TestEvent.swift
//  Demo
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import UIKit

class TestEvent: NSObject, NSCoding {

    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: "name") as! String
    }
}
