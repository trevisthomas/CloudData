//
//  CloudAuthorizationOperation.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/20/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation
import CloudKit

// NSNotification.Name.CKAccountChanged  This notification lets you know if the user changes

class CloudAuthOperation : BaseUserOperation {
    override func start() {
        state = .inProgress
        
        if isCancelled {
            state = .done
            return
        }
        
        if user.isAuthenticated {
            state = .done
            return
        }
        
        CKContainer.default().accountStatus(completionHandler: { (status: CKAccountStatus, error:Error?) in
            if let error = error {
                self.handleError(error)
            } else {
                self.accountStatus(status)
            }
            self.state = .done
        })
    }
    
    override func handleError(_ error : Error) {
        print(error)
        user.isAuthenticated = false
    }
    
    let alertMessage = "Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID."
    
    let alertTitle = "Sign in to iCloud"
    
    func accountStatus(_ status : CKAccountStatus) {
        if status == CKAccountStatus.noAccount {
            //TODO: Show alert
            user.isAuthenticated = false
        } else {
            user.isAuthenticated = true
        }
    }
}





