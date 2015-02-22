//
//  Memo.swift
//  Signal
//
//  Created by Mikhail Vroubel on 13/09/2014.
//
//

import Foundation

var MemoContext = "memo"

@objc(Memo) class Memo: NSObject {
    typealias KeySeq = NSArray
    
    var value = NSMutableDictionary()
    
    func get(key:String)->AnyObject? {
        return self.value.valueForKeyPath(key)
    }
    func set(key:String, value:AnyObject?) {
        self.value.setValue(value, forKey: key)
    }
    
    subscript (keySeq:KeySeq)->AnyObject? {
        get {
            var value:AnyObject? = self.value
            for key in keySeq {
                value = value?.valueForKeyPath(key as NSString)
            }
            return value
        }
        set {
            if let last = keySeq.lastObject as? NSString {
                var current: AnyObject? = self.value
                if keySeq.count > 1 {
                    let keys = keySeq.subarrayWithRange(NSRange(location: 0, length: keySeq.count - 1))
                    for key in keys {
                        var next: AnyObject? = current?.valueForKeyPath(key as NSString)
                        if next == nil {
                            next = NSMutableDictionary()
                            current?.setValue(next, forKey: key as NSString)
                        }
                        current = next
                    }
                }
                current?.setValue(newValue, forKey: last)
            }
        }
    }
    
    class func valueFor(target:AnyObject, keySeq:KeySeq) -> AnyObject? {
        var value:Memo? = nil;
        if keySeq.count > 0 {
            value = objc_getAssociatedObject(target, unsafeAddressOf(self)) as Memo?
        }
        return value?[keySeq]
    }
    
    class func setValue(value:AnyObject?, target:AnyObject, keySeq:KeySeq) {
        if keySeq.count > 0 {
            var memo = objc_getAssociatedObject(target, unsafeAddressOf(self)) as Memo?
            if memo == nil {
                memo = Memo()
                objc_setAssociatedObject(target,unsafeAddressOf(self), memo, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            }
            memo?[keySeq] = value
        }
    }
    
    class func valueFor(target:AnyObject, key:String) -> AnyObject? {
        return (objc_getAssociatedObject(target, unsafeAddressOf(self)) as Memo?)?.get(key)
    }
    
    class func setValue(value:AnyObject?, target:AnyObject, key:String) {
        setValue(value, target: target, keySeq:NSArray(object: key))
    }
}
