//
//  PPBatchStrategies.swift
//  PhonePe
//
//  Created by Jatin Arora on 09/01/17.
//  Copyright © 2017 PhonePe Internet Private Limited. All rights reserved.
//

import Foundation


public struct PPSizeBatchingStrategy {
    public var eventsBeforeIngestion: Int64 = 10
    public init() {}
}


public struct PPTimeBatchingStrategy {
    public var timeBeforeIngestion: Int64 = 10
    public init() {}
}
