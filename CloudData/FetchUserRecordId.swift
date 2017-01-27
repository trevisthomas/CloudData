//
//  FetchUserId.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/20/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

class FetchUserRecordId : BaseUserOperation {
    
    override func start() {
        state = .inProgress
        
        if let _ = user.recordId {
            done()
            return
        }
        
        if isCancelled {
            done()
            return
        }
        
        CKContainer.default().fetchUserRecordID { (recordId: CKRecordID?, error:Error?) in
            if let error = error {
                self.handleError(error)
            } else if let recordId = recordId {
                self.user.recordId = recordId
            } else {
                fatalError() //?
            }
            self.done()
        }
    }

}
