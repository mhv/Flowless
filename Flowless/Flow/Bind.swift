//
//  AsyncBind.swift
//  Signal
//
//  Created by Mikhail Vroubel on 07/02/2015.
//
//

import UIKit

@objc (OnceBind) class OnceBind:Bind {
    override class func setValue(left:NSObject, leftKey:String, right:NSObject, rightKey:String, mapper:Mapper) {
        if let x: AnyObject = mapper.to(right.valueForKeyPath(rightKey)) {
            left.setValue(x , forKeyPath: leftKey)
        }
    }
}

@objc (WriteBind) class WriteBind:Bind {
    override class func setValue(left:NSObject, leftKey:String, right:NSObject, rightKey:String, mapper:Mapper) {
        Flow<NSObject>.KVOValue(left, keyPath: leftKey).addSync {[weak right] x in
            right?.setValue(mapper.from(x), forKeyPath: rightKey); ()
            }.put(left.valueForKeyPath(leftKey) as? NSObject)
    }
}

@objc (ReadBind) class ReadBind:Bind {
    override class func setValue(left:NSObject, leftKey:String, right:NSObject, rightKey:String, mapper:Mapper) {
        Flow<NSObject>.KVOValue(right, keyPath: rightKey).addSync {[weak left] x in
            left?.setValue(mapper.to(x), forKeyPath: leftKey); ()
            }.put(right.valueForKeyPath(rightKey) as? NSObject)
    }
}

@objc (BothBind) class BothBind:Bind {
    override class func setValue(left:NSObject, leftKey:String, right:NSObject, rightKey:String, mapper:Mapper) {
        Flow<NSObject>.KVOValue(left, keyPath: leftKey).addSync {[weak right] x in
            right?.setValue(mapper.from(x), forKeyPath: rightKey); ()
        }
        weak var prev:NSObject?
        Flow<NSObject>.KVOValue(right, keyPath: rightKey).addSync {[weak left] x in
            if x != prev {
                prev = x
                left?.setValue(mapper.to(x) , forKeyPath: leftKey); ()
            }
            }.put(right.valueForKeyPath(rightKey) as? NSObject)
    }
}

@objc (Bind) public class Bind : NSObject {
    class func setValue(a:(left:NSObject, value: AnyObject?, keyPath: String)) {
        var rightInfo = a.value?.componentsSeparatedByString("@")
        if let var rightKey = rightInfo?.last as? String {
            var mapper = rightInfo?.count > 1 ? Mapper.pathMapper(rightInfo!.first as String)! : Mapper()
            if let var right = a.left.source(rightKey as String, target: a.left) {
                self.setValue(a.left, leftKey: a.keyPath, right: right, rightKey: rightKey,mapper: mapper);
            }
        }
    }
    override public class func setValue(value: AnyObject?, forKeyPath keyPath: String) {
        if let box = value as? Box<(UIResponder,String)> {
            BinderInstance.nextRun {
                self.setValue((box.value.0, box.value.1, keyPath))
            }
        }
    }
    class func setValue(left:NSObject, leftKey:String, right:NSObject, rightKey:String, mapper:Mapper) {
    }
}

var BinderInstance = Binder()
@objc (Binder) public class Binder : NSObject {
    var binds:NSMutableDictionary = ["Write":WriteBind.self, "Read":ReadBind.self, "Bind":BothBind.self, "Set":OnceBind.self]
    public override func setValue(value: AnyObject?, forKey key: String) {
        binds.setValue(value, forKey: key)
    }
    public override func valueForKey(key: String) -> AnyObject? {
        return binds.valueForKey(key)
    }
    public var instance:Binder {
        return BinderInstance;
    }
}

extension NSObject { // MARK: XXX id<Bindable>
    public func source(String, target:NSObject) -> NSObject? {
        return nil
    }
}

extension UIResponder {
    override public func source(key: String, target: NSObject) -> NSObject? {
        return self.nextResponder()?.source(key, target: target);
    }
    public override func valueForKeyPath(keyPath: String) -> AnyObject? {
        return keyPath.isEmpty ? self : super.valueForKeyPath(keyPath)
    }
    public override func setValue(value: AnyObject?, forUndefinedKey key: String) {
        if let v = (value as? String)?.stringByReplacingOccurrencesOfString(" ", withString: ".") {
            BinderInstance.setValue(Box(self,v), forKeyPath: key.stringByReplacingOccurrencesOfString(" ", withString: "."))
        }
    }
}


extension UIViewController {
    override public func source(key: String, target: NSObject) -> NSObject? {
        return contains(key,".") || self.valueForKey(key) != nil ? self : super.source(key, target: target);
    }
}

extension UITableViewCell {
    override public func source(key: String, target: NSObject) -> NSObject? {
        return contains(key,".") || self.valueForKey(key) != nil ? self : super.source(key, target: target);
    }
}

extension UICollectionViewCell {
    override public func source(key: String, target: NSObject) -> NSObject? {
        return contains(key,".") || self.valueForKey(key) != nil ? self : super.source(key, target: target);
    }
}