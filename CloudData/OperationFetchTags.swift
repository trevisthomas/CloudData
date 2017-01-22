//
//  OperationFetchTags.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/22/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

class OperationFetchTags : BaseOperation {
    private let enfocaId : NSNumber
    private let db : CKDatabase
    private(set) var tags : [Tag] = []
    
    init (enfocaId: NSNumber, db: CKDatabase) {
        self.enfocaId = enfocaId
        self.db = db
    }
    
    override func start() {
        isExecuting = true
        
        let sort : NSSortDescriptor = NSSortDescriptor(key: "Name", ascending: true)
        let predicate : NSPredicate = NSPredicate(format: "enfocaId == %@", enfocaId)
        
        let query: CKQuery = CKQuery(recordType: "SimpleTag", predicate: predicate)
        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        
        execute(operation: operation)
    }
    
    private func execute(operation : CKQueryOperation) {
        operation.recordFetchedBlock = {record in
            self.tags.append(self.toTag(from: record))
        }
        
        operation.queryCompletionBlock = {(cursor, error) in
            if let error = error {
                self.handleError(error)
                self.done()
            }
            
            if let cursor = cursor {
                let cursorOp = CKQueryOperation(cursor: cursor)
                self.execute(operation: cursorOp)
                return
            }
            self.done()
        }
        
        db.add(operation)
    }
    
    private func toTag(from record: CKRecord) -> Tag{
        let t = Tag()
        t.name = record.value(forKey: "Name") as! String!
        t.recordId = record.recordID
        return t
    }
    
    private func handleError(_ error : Error) {
        print(error)
    }
}
