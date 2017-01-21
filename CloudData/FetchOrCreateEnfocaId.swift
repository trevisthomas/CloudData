//
//  CreateEnfocaId.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/21/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

class FetchOrCreateEnfocaId : BaseUserOperation {
    
    override func start() {
        isExecuting = true
        
        if let id = user.record.value(forKey: "enfocaId") as? Int {
            user.enfocaId = id
            done()
            return
        }
        
        if isCancelled {
            done()
            return
        }
        
        guard let id = user.newEnfocaId else {
            fatalError() //Precondition not met
        }
        
        user.record.setValue(id, forKey: "enfocaId")
        CKContainer.default().publicCloudDatabase.save(user.record, completionHandler: { (record:CKRecord?, error:Error?) in
            if let error = error {
                self.handleError(error)
                fatalError() //Failed to update.   What to do!?
            }
            self.user.enfocaId = id
            self.done()
        })
    }
}
