//
//  Transform.swift
//  Misc
//
//  Created by Mikhail Vroubel on 09/09/2014.
//  Copyright (c) 2014 Mikhail Vroubel. All rights reserved.
//

import Foundation
import Beholder
import Utils

class Sink<T> {
    private var actions = SparseArray<(T)->Void>()
    func addAction(_ o:((T)-> Void)) -> Int {
        return actions.append(o)
    }
    func removeAction(_ i:Int) {
        actions[i: i] = nil
    }
    func put(_ x: T) {
        for (_,a) in actions {a(x)}
    }
}

public class Flow<T> {
    // MARK: -
    var next = Sink<T>()
    var done = Sink<NSError?>()
    // MARK: -
    deinit {
        finish()
    }
    // TODO: Flow().tap {setup}
    public init(setup:(Flow)->Void) {
        setup(self)
    }
    
    // MARK: -
    public func put(_ x: T) {
        next.put(x)
    }
    func finish(_ x:NSError? = nil) {
        done.put(x)
    }

    // MARK: -
    public func add(_ o:((T)-> Void)) -> Flow {
        _ = next.addAction(o)
        return self
    }
    public func end(_ o:((NSError?) -> Void)) -> Flow {
        _ = done.addAction(o)
        return self
    }
    public func ok(_ o:((Void)-> Void)) -> Flow {
        return end {if $0 == nil {o()}}
    }
    public func err(_ o:((NSError) -> Void)) -> Flow {
        return end {if let e = $0 {o(e)}}
    }
    
    // MARK: -
    func flow<U>(_ output:Flow<U>, put:(T)->Void) {
        let token = self.next.addAction(put)
        _ = output.done.addAction { [weak self] _ in
            self?.next.removeAction(token)
        }
    }
    public func map<U>(_ fun: (T) -> U) -> Flow<U> {
        return Flow<U> {flow in
            self.flow(flow) {flow.put(fun($0))}
        }
    }
    public func filter(_ fun: (T) -> Bool) -> Flow {
        return Flow {flow in
            self.flow(flow) {fun($0) ? flow.put($0) : ()}
        }
    }
    public func whiles(_ fun: (T) -> Bool) -> Flow {
        return Flow {flow in
            self.flow(flow) {fun($0) ? flow.put($0) : flow.finish()}
        }
    }
    public func once() -> Flow {
        return Flow {flow in
            self.flow(flow) {
                flow.put($0)
                flow.finish()
            }
        }
    }
    
    // MARK: -
    public class func any(_ ins:[Flow]) -> Flow {
        return Flow {flow in
            for f in ins {
                f.flow(flow, put:flow.put)
            }
        }
    }
    public class func all(_ ins:[Flow]) -> Flow<([T])> {
        var prepared:[Int:T]? = [Int:T]()
        var value:[T]!
        let count = ins.count
        return Flow<([T])> {flow in
            for (i, f) in ins.enumerated() {
                f.flow(flow) {
                    if (prepared != nil) {
                        prepared?[i] = $0
                        if (prepared?.count == count) {
                            value = prepared!.map {$1}
                            prepared = nil
                        }
                    }
                    if (!(prepared != nil)) {
                        value[i] = $0
                        flow.put(value)
                    }

                }
            }
        }
    }
    
    // MARK: -
    public func then() -> Flow<NSError?> {
        return Flow<NSError?> {flow in
            let token = self.done.addAction(flow.put)
            _ = flow.done.addAction { [weak self] _ in
                self?.done.removeAction(token)
            }
        }
    }

    // MARK: -
    public func dispatch(_ q:DispatchQueue) -> Flow {
        return Flow { flow in
            self.flow(flow) { x in
                q.async {flow.put(x)}
            }
        }
    }
    public func operation(_ q:OperationQueue) -> Flow {
        return Flow { flow in
            self.flow(flow) { x in
                q.addOperation {flow.put(x)}
            }
        }
    }
    public func background() -> Flow {
        return self.dispatch(DispatchQueue.global(qos: DispatchQoS.QoSClass.background))
    }
    public func main() -> Flow {
        return self.dispatch(DispatchQueue.main)
    }

    // MARK: -
    public class func source(_ source:NSObject, name:String) -> Flow<Notification> {
        return Flow<Notification> { flow in
            weak var o = source.observeName(name) {flow.put($0)}
            _ = flow.done.addAction {_ in o?.finish()}
        }
    }
    public class func source(_ source:NSObject, keyPath:String) -> Flow<AnyObject> {
        return Flow<AnyObject> { flow in
            weak var o = source.observeKeyPath(keyPath) {flow.put($0[NSKeyValueChangeKey.newKey]!)}
            _ = flow.done.addAction {_ in o?.finish()}
        }
    }
    public class func sourceDealloc(_ source:NSObject) -> Flow<NSObject> {
        return Flow<NSObject> { flow in
            weak var o = source.observe {[weak source] in flow.put(source!)}
            _ = flow.done.addAction {_ in o?.finish()}
        }
    }
}
