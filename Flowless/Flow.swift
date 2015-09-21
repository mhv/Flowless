//
//  Transform.swift
//  Misc
//
//  Created by Mikhail Vroubel on 09/09/2014.
//  Copyright (c) 2014 Mikhail Vroubel. All rights reserved.
//

import Foundation

class Sink<T> {
    private var actions = SparseArray<T->()>()
    func put(x: T) {
        for (_,a) in actions {a(x)}
    }
    func addOutput(o:(T-> ())) -> Int {
        return actions.append(o)
    }
    func removeOutput(i:Int) {
        actions[i: i] = nil
    }
}

public class Flow<T> {
    var next = Sink<T>()
    var done = Sink<NSError?>()
    public func put(x: T) {
        next.put(x)
    }
    public func add(o:(T-> ())) -> Flow {
        next.addOutput(o)
        return self
    }
    public func end(o:(NSError? -> ())) -> Flow {
        done.addOutput(o)
        return self
    }
    public func endOk(o:(()-> ())) -> Flow {
        return end {if $0 == nil {o()}}
    }
    public func endErr(o:(NSError -> ())) -> Flow {
        return end {if let e = $0 {o(e)}}
    }
    func finish(x:NSError?) {
        done.put(x)
    }
    public func cancel() {
        finish(nil)
    }
    deinit {
        cancel()
    }
    func addInput<U>(input:Flow<U>, put:(U)->()) {
        let token = input.next.addOutput(put)
        self.done.addOutput { [weak input] _ in
            input?.next.removeOutput(token)
        }
    }
    public init(setup:(Flow)->()) {
        setup(self)
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
            flow.addInput(self) {fun($0) ? flow.put($0) : flow.cancel()}
        }
    }
    public func once() -> Flow {
        return Flow {flow in
            flow.addInput(self) {
                flow.put($0)
                flow.cancel()
            }
        }
    }
    public class func flatten(ins:[Flow]) -> Flow {
        return Flow {flow in
            for f in ins {
                flow.addInput(f, put:flow.put)
            }
        }
    }
    public class func combine(ins:[Flow]) -> Flow<([Int:T])> {
        var value = [Int:T]()
        let count = ins.count
        return Flow<([Int:T])> {flow in
            for (i, f) in ins.enumerate() {
                flow.addInput(f) {
                    value[i] = $0
                    if (value.count == count) {
                        flow.put(value)
                    }
                }
            }
        }
    }

    func addSink<U>(input:Sink<U>, put:(U->())) {
        let token = input.addOutput(put)
        self.done.addOutput { [weak input] _ in
            input?.removeOutput(token)
        }
    }

    public func then() -> Flow<NSError?> {
        return Flow<NSError?> {flow in
            flow.addSink(self.done, put: flow.put)
        }
    }

    public func dispatch(q:dispatch_queue_t) -> Flow {
        return Flow { flow in
            flow.addInput(self, put: { x in
                dispatch_async(q) {flow.put(x)}
            })
        }
    }

    public func operation(q:NSOperationQueue) -> Flow {
        return Flow { flow in
            flow.addInput(self, put: { x in
                q.addOperationWithBlock {flow.put(x)}
            })
        }
    }
    public func bg() -> Flow {
        return self.dispatch(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    }
    public func main() -> Flow {
        return self.dispatch(dispatch_get_main_queue())
    }
    public class func source(source:NSObject, name:String) -> Flow<NSNotification> {
        return Flow<NSNotification> { flow in
            weak var o = source.observeName(name) {flow.put($0)}
            flow.done.addOutput {_ in o?.cancel()}
        }
    }
    public class func source(source:NSObject, keyPath:String) -> Flow<AnyObject> {
        return Flow<AnyObject> { flow in
            weak var o = source.observeKeyPath(keyPath)
                {flow.put($0[NSKeyValueChangeNewKey]!)}
            flow.done.addOutput {_ in o?.cancel()}
        }
    }
    public class func sourceDealloc(source:NSObject) -> Flow<NSObject> {
        return Flow<NSObject> { flow in
            weak var o = source.observe {[weak source] in flow.put(source!)}
            flow.done.addOutput {_ in o?.cancel()}
        }
    }
}
