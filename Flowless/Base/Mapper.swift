//
//  File.swift
//  Signal
//
//  Created by Mikhail Vroubel on 07/02/2015.
//
//

import UIKit

@objc (LoudMapper) public class LoudMapper:Mapper {
    var mapper:Mapper
    public init (name:String? = nil, mapper:Mapper) {
        self.mapper = mapper
        super.init()
        self.name = name
    }
    var flow = Flow<(AnyObject?,AnyObject?, to:Bool)>()
    override func to(x: AnyObject?) -> AnyObject? {
        let res:AnyObject? = mapper.to(x)
        flow.put(x, res, to: true)
        return res;
    }
    override func from(x: AnyObject?) -> AnyObject? {
        let res:AnyObject? = mapper.from(x)
        flow.put(x, res, to: false)
        return res;
    }
}

@objc (ClosureMapper) public class ClosureMapper:Mapper {
    let _to:AnyObject?->AnyObject?
    override func to(t: AnyObject?) -> AnyObject? {return _to(t)}
    let _from:AnyObject?->AnyObject?
    override func from(u: AnyObject?) -> AnyObject? {return _from(u)}
    public init (name:String? = nil, to:AnyObject?->AnyObject? = {_ in nil}, from:AnyObject?->AnyObject? = {_ in nil}) {
        (self._to, self._from) = (to, from)
        super.init()
        self.name = name
    }
}

@objc (Mapper) public class Mapper {
    public class func load() {
        ClosureMapper(name: "!", to: {return NSNumber(bool: !($0 as NSNumber).boolValue)}, from: {return NSNumber(bool: !($0 as NSNumber).boolValue)})
    }
    public init () {}
    var name:String? {
        willSet {
            var slf = self
            if let key = name {
                if Memo.valueFor(Mapper.self, key: key) === self {
                    Memo.setValue(nil, target: Mapper.self, key: key)
                }
            }
            if let key = newValue {
                Memo.setValue(self, target: Mapper.self, key: key)
            }
        }
    }
    func to(t:AnyObject?)->AnyObject? {return t}
    func from(u:AnyObject?)->AnyObject? {return u}
    class func named(name:String) -> Mapper? {
        return Memo.valueFor(Mapper.self, key: name) as Mapper?
    }
    class func pathMapper(name:String) -> Mapper? {
        var mappers = name.componentsSeparatedByString(".").map(Mapper.named)
        return ClosureMapper(
            to:{reduce(mappers.reverse(), $0) { res, next in next?.to(res)}},
            from: {reduce(mappers, $0) { res, next in next?.from(res)}}
        );
    }
}
