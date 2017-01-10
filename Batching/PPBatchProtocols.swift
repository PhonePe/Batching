//
//  PPBatchingProtocols.swift
//  PhonePe
//
//  Created by Jatin Arora on 09/01/17.
//  Copyright © 2017 PhonePe Internet Private Limited. All rights reserved.
//

import Foundation


protocol BatchSerializable {
    
    func isValidJSON() -> Bool
    func jsonRepresentation() -> Data?
    func dictionaryRepresentation() -> [String: Any]
    
}

