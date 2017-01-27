//
//  ReadWriteMutex.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/23/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation

public final class ReadWriteMutex {
    private var imp = pthread_rwlock_t()
    
    public init() {
        pthread_rwlock_init(&imp, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&imp)
    }
    
    @discardableResult public func reading<T>(_ closure: () throws -> T) rethrows -> T {
        defer { pthread_rwlock_unlock(&imp) }
        pthread_rwlock_rdlock(&imp)
        return try closure()
    }
    
    @discardableResult public func writing<T>(_ closure: () throws -> T) rethrows-> T {
        defer { pthread_rwlock_unlock(&imp) }
        pthread_rwlock_wrlock(&imp)
        return try closure()
    }
}
