//
//  PPBatchUtils.swift
//  Batching
//
//  Created by Jatin Arora on 13/01/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import Foundation


struct PPBatchUtils {

    static func createDirectoryIfNotExists(at path: String) {
        
        if FileManager.default.fileExists(atPath: path) == false {
            
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                assert(false, "Unable to create DB directory for Batching Pod")
            }
            
        }
        
    }
    
}
