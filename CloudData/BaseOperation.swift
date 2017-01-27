//
//  BaseOperation.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/20/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation

//I'm not sure that i understand the threading model in this tech stack.  Documentation seemed to say that i needed to protect these.  Since this BS language doesnt have mutexes and semaphores out of the box i tried this DispatchQueue stuff but i was getting exceptions.  I threw up my hands and just commented it out.

// The mutex class that i'm using is from David.  He also had an idea about tracking the state in an enum instead of the two seperate goofy booleans.  I think that i like it.

class BaseOperation : Operation {
    
    private var _state : OperationState = .initial
    
    var state : OperationState {
        get {
            return mutex.reading {_state}
        }
        
        set {
            mutex.writing {
                _state = newValue
                switch (newValue) {
                case .initial:
                    self.willChangeValue(forKey: "isExecuting")
                    self.didChangeValue(forKey: "isExecuting")
                    
                    self.willChangeValue(forKey: "isFinished")
                    self.didChangeValue(forKey: "isFinished")
                case .inProgress:
                    self.willChangeValue(forKey: "isExecuting")
                    self.didChangeValue(forKey: "isExecuting")
                case .done:
                    self.willChangeValue(forKey: "isExecuting")
                    self.didChangeValue(forKey: "isExecuting")
                    
                    self.willChangeValue(forKey: "isFinished")
                    self.didChangeValue(forKey: "isFinished")
                }
            }
        }
    }
    
    let mutex = ReadWriteMutex()
    
    //TODO: Use this.
    enum OperationState {
        case initial
        case inProgress
        case done
    }
    
    override init() {
        super.init()
        mutex.writing {
            state = .initial
        }
    }
    
    func done(){
        mutex.writing {
            state = .done
        }
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool{
        get {
            return mutex.reading{
                state == .inProgress
            }
        }
    }
    
    override var isFinished: Bool {
        get {
            return mutex.reading{ state == .done }
        }
    }
}
