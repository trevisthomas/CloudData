//
//  FetchIncrementAndSaveSeed.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/21/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

class FetchIncrementAndSaveSeedIfNecessary : BaseUserOperation {
    
    override func start() {
        if let _ = user.record.value(forKey: "enfocaId") as? Int {
            //If he has an enfoca id, then incrementing the seed is not necessary
            done()
            return
        }
        
        let db = CKContainer.default().publicCloudDatabase
        state = .inProgress
        
        let settingsId = CKRecordID(recordName: "9ea8a03a-9867-4365-8ece-94380971bc13")
        
        
        db.fetch(withRecordID: settingsId, completionHandler: { (record: CKRecord?, error: Error?) in
            guard let id = record?.value(forKey: "Seed") as? Int, let record = record else {
                //Settings record doesnt exist
                fatalError()
            }
            let enfocaId = id + 1
            record.setValue(enfocaId, forKey: "Seed")
            db.save(record, completionHandler: { (record:CKRecord?, error:Error?) in
                if let error = error {
                    print(error)
                    fatalError() //Handle error.  Here is where we'd end up if the error record was updated while you were updating it
                }
                self.user.newEnfocaId = enfocaId
                
                self.done()
            })
        })
    }
    
}
