//
//  BaseOperation.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/20/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import Foundation

//I'm not sure that i understand the threading model in this tech stack.  Documentation seemed to say that i needed to protect these.  Since this BS language doesnt have mutexes and semaphores out of the box i tried this DispatchQueue stuff but i was getting exceptions.  I threw up my hands and just commented it out.

class BaseOperation : Operation {
//    let mutex: DispatchQueue
    
    private var _executing: Bool = false
    private var _finished: Bool = false
    
    
    override init() {
        super.init()
        self.isFinished = false
        self.isExecuting = false
    }
    
    func done(){
        self.isFinished = true
        self.isExecuting = false
    }
    
//    init(mutexName: String) {
//        mutex = DispatchQueue(label: mutexName) //Trevis, heads up.  Check out the
//    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
//    override var isReady: Bool {
//        return true  // Necessary?
//    }
    
    override var isExecuting: Bool{
        get {
            var executing : Bool!
//            mutex.sync {
                executing = _executing
//            }
            return executing
        }
        set {
//            mutex.sync {
                self.willChangeValue(forKey: "isExecuting")
                _executing = newValue
                self.didChangeValue(forKey: "isExecuting")
//            }
        }
    }
    
    override var isFinished: Bool {
        get {
            var finished : Bool!
//            mutex.sync {
                finished = _finished
//            }
            return finished
        }
        set {
//            mutex.sync {
                self.willChangeValue(forKey: "isFinished")
                _finished = newValue
                self.didChangeValue(forKey: "isFinished")
//            }
        }
    }
}
