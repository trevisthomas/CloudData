//
//  OperationsDemo.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/20/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

class OperationsDemo {
    class func authentcate() -> Int{
        let user : User = User()
        
        let queue = OperationQueue()
        
        let fetchUserId = FetchUserRecordId(user: user)
        let cloudAuth = CloudAuthOperation(user: user)
        let fetchUserRecord = FetchUserRecordOperation(user: user)
        let fetchOrCreateEnfocaId = FetchOrCreateEnfocaId(user: user)
        let fetchIncrementAndSaveSeedIfNecessary = FetchIncrementAndSaveSeedIfNecessary(user: user)
        
        fetchUserId.addDependency(cloudAuth)
        fetchUserRecord.addDependency(fetchUserId)
        fetchIncrementAndSaveSeedIfNecessary.addDependency(fetchUserRecord)
        fetchOrCreateEnfocaId.addDependency(fetchIncrementAndSaveSeedIfNecessary)
        
        queue.addOperations([fetchUserId, cloudAuth, fetchUserRecord, fetchOrCreateEnfocaId, fetchIncrementAndSaveSeedIfNecessary], waitUntilFinished: true)
        
        print(user.recordId)
        return user.enfocaId
    
    }
}


