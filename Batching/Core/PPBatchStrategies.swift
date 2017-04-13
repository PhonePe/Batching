//
//  PPBatchStrategies.swift
//  PhonePe
//
//  Created by Jatin Arora on 09/01/17.
//  Copyright © 2017 PhonePe Internet Private Limited. All rights reserved.
//

import Foundation


public struct PPSizeBatchingStrategy {
    public var eventsBeforeIngestion: Int64
    
    public init(eventsBeforeIngestion: Int64 = 10) {
        self.eventsBeforeIngestion = eventsBeforeIngestion
    }
}


public struct PPTimeBatchingStrategy {
    public var durationBeforeIngestion: Double
    
    public init(durationBeforeIngestion: Double = 10) {
        self.durationBeforeIngestion = durationBeforeIngestion
    }
}
