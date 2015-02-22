//
//  KVObserver.swift
//  Signal
//
//  Created by Mikhail Vroubel on 13/09/2014.
//
//

import Foundation

// @KVObserver is retained by observed @owner and stops observing automatically
@objc (KVObserver) class KVObserver: Ownee {
    var action:[NSObject : AnyObject] -> ()
    init(object:NSObject, keyPath:String, options:NSKeyValueObservingOptions = .New, action:([NSObject : AnyObject]) -> ()) {
        self.action = action
        super.init(owner: object, context: OwneeOwner + "." + keyPath)
        self.addObserver(self, forKeyPath: self.context as String, options: options, context: &self.context)
    }
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &self.context {
            self.action(change)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    override func finish() {
        if context != nil {
            self.owner = nil
            self.removeObserver(self, forKeyPath: context as String, context:&self.context)
        }
        super.finish()
    }
}
