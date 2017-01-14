//
//  Models.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/12/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

class WordPair {
    var recordId: CKRecordID! //Trevis, this feels like such a bad idea.
    var word: String = ""
    var definition: String = ""
    var tags : [Tag] = []
}

class Tag : CustomStringConvertible {
    var name: String = ""
    var recordId: CKRecordID! //Trevis, this feels like such a bad idea.
    
    var description: String {
        return name
    }
}
