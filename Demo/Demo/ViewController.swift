//
//  ViewController.swift
//  Demo
//
//  Created by Jatin Arora on 13/04/17.
//  Copyright © 2017 Jatin Arora. All rights reserved.
//

import UIKit
import Batching

class ViewController: UIViewController {

    var batchManager: PPBatchManager!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup Batching library
        let timeStrategy = PPTimeBatchingStrategy()
        
        batchManager = PPBatchManager(sizeStrategy: PPSizeBatchingStrategy(), timeStrategy: timeStrategy, dbName: "Batching")
        batchManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        for i in 0..<10 {
            let testEvent = TestEvent(name: "Event \(i)")
            batchManager.addToBatch(testEvent, timestamp: Date().timeIntervalSince1970)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


extension ViewController: PPBatchManagerDelegate {

    func batchManagerShouldIngestBatch(_ manager: PPBatchManager, batch: [Any], completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
}
