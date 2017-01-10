//
//  PPBatchStrategies.swift
//  PhonePe
//
//  Created by Jatin Arora on 09/01/17.
//  Copyright © 2017 PhonePe Internet Private Limited. All rights reserved.
//

import Foundation


struct PPSizeBatchingStrategy {
    let numberOfEventsBeforeIngestion: Int64
}


struct PPTimeBatchingStrategy {
    let timeBeforeIngestion: Int64
}
