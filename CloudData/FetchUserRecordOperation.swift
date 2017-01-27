//
//  FetchUserRecordOperation.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/20/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

class FetchUserRecordOperation : BaseUserOperation {
    
    override func start() {
        state = .inProgress
        
        if let _ = user.record {
            self.done()
            return
        }
        
        if isCancelled {
            self.done()
            return
        }
        
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: user.recordId) { (record:CKRecord?, error:Error?) in
            if let error = error {
                self.handleError(error)
            } else if let record = record {
                self.user.record = record
            } else {
                fatalError() //?
            }
            self.done()
        }
    }
}
