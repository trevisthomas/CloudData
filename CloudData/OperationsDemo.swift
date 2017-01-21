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
    
//    class func generateEnfocaId() -> Int {
//        
//        let queue = OperationQueue()
//        let operation = FetchIncrementAndSaveSeed()
//        
//        queue.addOperations([operation], waitUntilFinished: true)
//        
//        return operation.newEnfocaId!
//    }
//    
//    func createLoadOperation() -> CKOperation {
//        let settingsId = CKRecordID(recordName: "9ea8a03a-9867-4365-8ece-94380971bc13")
//        
//        let predicate = NSPredicate(format: "recordID == %@", settingsId)
//        let query = CKQuery(recordType: "Global", predicate: predicate)
//        let operation = CKQueryOperation(query: query)
//        
//        //add callbacks
//        
//        return operation
//    }
//    
//    func createSaveOperation() -> CKOperation {
//        CKModifyRecordsOperation(recordsToSave: <#T##[CKRecord]?#>, recordIDsToDelete: <#T##[CKRecordID]?#>)
//    }
//    
//    
//    func createEnfocaId(callback: @escaping (Int?) -> ()){
//        let settingsId = CKRecordID(recordName: "9ea8a03a-9867-4365-8ece-94380971bc13")
//        
//        
//        self.db.fetch(withRecordID: settingsId, completionHandler: { (record: CKRecord?, error: Error?) in
//            guard let id = record?.value(forKey: "Seed") as? Int, let record = record else {
//                callback(nil)
//                return
//            }
//            let enfocaId = id + 1
//            record.setValue(enfocaId, forKey: "Seed")
//            self.db.save(record, completionHandler: { (record:CKRecord?, error:Error?) in
//                if let error = error {
//                    print(error)
//                    fatalError() //Handle error.  Here is where we'd end up if the error record was updated while you were updating it
//                }
//                self.updateUserRecord(enfocaId: enfocaId, callback: { (success: Bool) in
//                    if success {
//                        callback(enfocaId)
//                    } else {
//                        fatalError()//Failed to save the record to the user!
//                    }
//                })
//                
//            })
//        })
//    }
    
    
//    class FetchIncrementAndSaveSeed : BaseOperation {
//        var newEnfocaId : Int?
//        
//        override func start() {
//            let db = CKContainer.default().publicCloudDatabase
//            isExecuting = true
//            
//            let settingsId = CKRecordID(recordName: "9ea8a03a-9867-4365-8ece-94380971bc13")
//            
//            
//            db.fetch(withRecordID: settingsId, completionHandler: { (record: CKRecord?, error: Error?) in
//                guard let id = record?.value(forKey: "Seed") as? Int, let record = record else {
//                    //Settings record doesnt exist
//                    fatalError()
//                }
//                let enfocaId = id + 1
//                record.setValue(enfocaId, forKey: "Seed")
//                db.save(record, completionHandler: { (record:CKRecord?, error:Error?) in
//                    if let error = error {
//                        print(error)
//                        fatalError() //Handle error.  Here is where we'd end up if the error record was updated while you were updating it
//                    }
//                    self.newEnfocaId = enfocaId
//                    
//                    self.done()
//                })
//            })
//        }
//        
//    }
}


