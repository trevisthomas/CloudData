//
//  BaseUserOperation.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/21/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation

class BaseUserOperation : BaseOperation {
    public let user : User
    
    init(user : User){
        self.user = user
        super.init()
        qualityOfService = .userInitiated
    }
    
    func handleError(_ error : Error) {
        print(error)
        fatalError() //Shrug?  
    }
}
