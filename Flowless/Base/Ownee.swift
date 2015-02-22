//
//  Ownee.swift
//  Signal
//
//  Created by Mikhail Vroubel on 13/09/2014.
//
//

import UIKit

let OwneeOwner = "unsafeOwner"

/// @Ownee is retained by its @owner
@objc (Ownee) public class Ownee: OwneeBase {
    @IBOutlet public var context:AnyObject?
    @IBOutlet public weak var owner:NSObject? {
        willSet {
            willSet(owner, newValue: newValue)
        }
    }
    func willSet(owner:NSObject?, newValue:NSObject?) {
        if owner != newValue {
            if newValue != nil {
                objc_setAssociatedObject(newValue, unsafeAddressOf(self), self, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            }
            if owner != nil {
                objc_setAssociatedObject(owner, unsafeAddressOf(self), nil, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            }
        }
        unsafeOwner = newValue
        
    }
    public func finish() {
        if owner != nil {
            owner = nil;
        }
        context = nil
    }
    public init(owner:NSObject, context:AnyObject? = nil) {
        super.init()
        willSet(nil, newValue: owner)
        (self.owner, self.context) = (owner, context)
    }
    deinit {
        finish()
    }
}
