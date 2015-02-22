//
//  Transform.swift
//  Misc
//
//  Created by Mikhail Vroubel on 09/09/2014.
//  Copyright (c) 2014 Mikhail Vroubel. All rights reserved.
//

import UIKit
@objc(OCFlow) public class OCFlow:NSObject {
    var flow:Flow<NSObject?>
    init (flow:Flow<NSObject?>? = nil) {
        self.flow = flow ?? Flow<NSObject?>()
    }
    public func addSync(fun: NSObject? -> ()) -> OCFlow {
        self.flow.addSync(fun)
        return self
    }
    
    public func put (x:NSObject?) {
        flow.put(x)
    }
    public class func KVOValue(object: NSObject, keyPath: String) -> OCFlow {
        return OCFlow(flow: Flow<NSObject?>.KVO(object, keyPath: keyPath).map { x in
            var res:AnyObject? = x[NSKeyValueChangeNewKey]
            return (res is NSNull) ? nil : res as NSObject?
            })
    }
    
}

public class Flow<T>: Equatable, SinkType {  // MARK: Internals
    typealias Fin = () -> ()
    
    private var actions = SparseArray<T->()>()
    private var finals = SparseArray<Fin>()
    
    private var lock = Lock()
    
    var input:(Flow, T) -> ()
    
    public func finish () {
        lock.locked { () -> () in
            self.input = {_,_ in return}
            Swift.map(self.finals) {$0.1()}
            self.actions = SparseArray<T->()>()
            self.finals = SparseArray<Fin>()
        }
    }
    
    deinit {
        finish()
    }
    
    func addInput<U> (src:Flow<U>, o:(U)->())->() {
        var finIdx:Int?
        let actIdx = src.actions.append(o)
        let selfIdx = finals.append {[weak src] in
            src?.actions.removeAtIndex(actIdx)
            src?.finals.removeAtIndex(finIdx!)
        }
        finIdx = src.finals.append {[weak self] in
            self?.finals.removeAtIndex(selfIdx); ()
        }
    }
    
    func starts(fun: (Flow, T) -> ()) -> Flow {
        var start = {(flow:Flow) -> () in
            flow.addInput(self) {flow.put($0)}
        }
        return Flow (start:start, put:fun)
    }
    
    class func regroup<U> (ins:[Flow], fun: (Int, T) -> [U], put:((Flow<U>, U) -> ())? = nil) -> Flow<U> {
        let start:(Flow<U>) -> () = {flow in
            for (idx, src) in enumerate(ins) {
                flow.addInput(src) {x in
                    fun(idx, x).map(flow.put); ()
                }
            }
        }
        return Flow<U>(start: start, put:put)
    }
    
    func defaultPut(x:T) {
        Schedule.splice(Swift.map(self.actions) {_, a in {a(x)}}, atIndex: 0)
        //        Swift.map(src.actions) {$0.1(x)}
    }
    init(start:((Flow) -> ())? = nil, put:((Flow, T) -> ())? = nil) {
        self.input = put != nil ? put! : {src, x in src.defaultPut(x)}
        start?(self)
    }
}

extension Flow {  // MARK: Chaining
    public func put (x:T) {
        input(self, x)
    }
    
    func output(out:Flow)->Flow {
        out.addInput(self) {out.input(out, $0)}
        return out
    }
    
    public func addSync(fun: T -> ()) -> Flow {
        self.actions.append(fun)
        return self
    }
    
    public func finally(fun: () -> ()) -> Flow {
        self.finals.append(fun)
        return self
    }
    
    public func addAsync(q:dispatch_queue_t = dispatch_get_main_queue(), fun: T -> ()) -> Flow {
        self.actions.append {v in dispatch_async(q) {fun(v)}}
        return self
    }
    
    public func sync(fun: T -> ()) -> Flow {
        return Flow {flow in
            flow.actions.append(fun)
            flow.addInput(self) {flow.put($0)}
        }
    }
    
    public func async(q:dispatch_queue_t = dispatch_get_main_queue(), fun: T -> ()) -> Flow {
        return Flow {flow in
            flow.actions.append(fun)
            flow.addInput(self) {v in dispatch_async(q) {flow.put(v)}}
        }
    }
    
    public func map<U>(fun: T -> U) -> Flow<U> {
        return Flow<U> {flow in
            flow.addInput(self) {flow.put(fun($0))}
        }
    }
    
    public func filter(fun: T -> Bool) -> Flow {
        return Flow {flow in
            flow.addInput(self) {fun($0) ? flow.put($0) : ()}
        }
    }
    
    public func whiles(fun: T -> Bool) -> Flow {
        return Flow {flow in
            flow.addInput(self) {fun($0) ? flow.put($0) : flow.finish()}
        }
    }
    
    public func onces<U>(fun: T -> U) -> Flow<U> {
        return Flow<U> {flow in
            flow.addInput(self) {flow.put(fun($0))}
            flow.finish()
        }
    }
    
    public func choose(outs:[Flow], fun: T -> Int) -> Flow {
        let src = starts {src, x in
            if let out = src.actions[fun(x)] {out(x)}
        }
        outs.map {flow in
            flow.addInput(src) {flow.put($0)}
        }
        return src
    }
    
    public class func any (ins:[Flow], put:((Flow, T) -> ())? = nil) -> Flow {
        return regroup(ins, {return [$0.1]},  put)
    }
    
    public class func combine (ins:[Flow], put:((Flow<[T]>, [T]) -> ())? = nil) -> Flow<[T]> {
        let count = ins.count
        var values = [T?](count: count, repeatedValue: nil)
        let fun:((Int, T)->[[T]]) = { idx, x in
            values[idx] = x
            return (values.count == count) ? [values.map{$0!}] : []  // XXX should map once
        }
        return regroup(ins, fun, put)
    }
}

let kBox = ">box"

public func BoxInfo<T>(x:T)->[NSObject :AnyObject] {
    return [kBox : Box<T>(x)]
}

public func UnboxInfo<T>(info:[NSObject :AnyObject]?)->T? {
    return (info?[kBox] as? Box<T>)?.value
}

public func Post(name:String! = nil, object: AnyObject? = nil, userInfo:[NSObject : AnyObject]? = nil) {
    NSNotificationCenter.defaultCenter().postNotificationName(name, object: object, userInfo:userInfo)
}

extension Flow {  // MARK: Observes
    public class func noteValue(name:String! = nil, object: AnyObject? = nil) -> Flow {
        return note(name: name, object: object).map {UnboxInfo($0.userInfo)!}
    }
    
    public class func note(name: String? = nil, object: AnyObject? = nil) -> Flow<NSNotification> {
        return Flow<NSNotification> {flow in
            let token = NSNotificationCenter.defaultCenter().addObserverForName(name, object:object, queue:nil) { [weak flow] in
                flow?.put($0); ()
            }
            var observer = Ownee(owner:object as? NSObject ?? NSNull(), context: flow)
            flow.finals.append {[weak observer] in
                NSNotificationCenter.defaultCenter().removeObserver(token)
                observer?.finish()
            }
        }
    }
    
    public class func KVOValue(object: NSObject, keyPath: String) -> Flow<T?> {
        return KVO(object, keyPath: keyPath).map { x in
            var res:AnyObject? = x[NSKeyValueChangeNewKey]
            return (res is NSNull) ? nil : res as? T
        }
    }
    
    public class func KVO(object: NSObject, keyPath: String, options: NSKeyValueObservingOptions = .New) -> Flow<[NSObject:AnyObject]> {
        return Flow<[NSObject:AnyObject]> {flow in
            let observer = KVObserver(object: object, keyPath: keyPath, options: options) {flow.put($0)}
            flow.finals.append {[weak observer] in observer?.finish(); ()}
        }
    }
    
    public class func notify(name:String! = nil, object: AnyObject? = nil, value:T) {
        Post(name: name, object: object, userInfo: BoxInfo(value))
    }
    
    public func notify(name:String! = nil, object: AnyObject? = nil) -> Flow {
        return Flow {flow in
            flow.addInput(self) {
                Flow.notify(name: name, object: object, value: $0)
                flow.put($0)
            }
        }
    }
}

extension Flow {  // MARK: Control Flow
    public func dispatch(q:dispatch_queue_t = dispatch_get_main_queue()) -> Flow {
        return starts {src, x in
            dispatch_async(q) {src.defaultPut(x)}
        }
    }
    
    public func queue(q:NSOperationQueue = NSOperationQueue.mainQueue()) -> Flow {
        return starts {src, x in
            q.addOperationWithBlock {src.defaultPut(x)}
        }
    }
}

public func == <T>(lhs: Flow<T>, rhs: Flow<T>) -> Bool {return lhs === rhs}

infix operator !> {associativity left}
infix operator /> {associativity left}
infix operator *> {associativity left}
public func /> <A>(l:(object: NSObject, keyPath:String), a: (A?) -> ()) -> Flow<A?> {
    return Flow<A>.KVOValue(l.object, keyPath: l.keyPath).sync(a)
}

public func *> <A>(l:(name:String, object: AnyObject?), a: (NSNotification) -> A) -> Flow<A> {
    return Flow<NSNotification>.note(name: l.name, object: l.object).map(a)
}

public func !> <A>(l:(control:UIControl, event: UIControlEvents), a: (UIControl) -> A) -> Flow<A> {
    var (control, e) = l
    var ownee = Ownee(owner: control, context: Flow<UIControl>())
    control.addTarget(ownee.context, action: "put:", forControlEvents: e)
    (ownee.context as Flow<UIControl>).finally {[weak control, weak ownee] in
        control?.removeTarget(ownee!.context, action: "put:", forControlEvents: e)
        ownee?.finish()
    }
    return (ownee.context as Flow<UIControl>).map(a)
}

public func *> <A, B>(f: Flow<A>, a: A -> B) -> Flow<B> {
    return f.map(a)
}

public func /> <A>(f: Flow<A>, a: A -> ()) -> Flow<A> {
    return f.sync(a)
}

public func /> <A>(f: Flow<A>, q: dispatch_queue_t) -> Flow<A> {
    return f.dispatch(q: q)
}

public func /> <A>(f: Flow<A>, q: NSOperationQueue) -> Flow<A> {
    return f.queue(q: q)
}
