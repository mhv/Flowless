//
//  Schedule.swift
//  Flowless
//
//  Created by Mikhail Vroubel on 21/02/2015.
//  Copyright (c) 2015 my. All rights reserved.
//

import Foundation

var lock = Lock()
// XXX for each threqueue...
typealias Fin = ()->()

class Schedule {
    class func splice(newElements: [Fin], atIndex i: Int) {
        var willStart = Actions.value.count == 0
        lock.locked { () -> () in
            self.Actions.value.splice(newElements, atIndex: i); ()
        }
        willStart ? start() : ()
    }
    
    class func start() {
        while Actions.value.count > 0 {
            lock.locked {self.Actions.value.removeAtIndex(0)} ()
        }
    }
    class var Actions:Box<[Fin]> {
        var actions: AnyObject? = NSThread.currentThread().threadDictionary["Actions"]
        if (actions == nil) {
            actions = Box([Fin]())
            NSThread.currentThread().threadDictionary["Actions"] = actions
        }
        return (actions as Box<[Fin]>)
    }
}
