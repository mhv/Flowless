//
//  Pusher+Utils.swift
//  Signal
//
//  Created by Mikhail Vroubel on 13/09/2014.
//
//

import UIKit

infix operator |> {associativity left}
infix operator <| {associativity right}

public func |> <A, B>(a: A, f: A -> B) -> B {
    return f(a)
}
public func <| <A, B>(f: A -> B, a: A) -> B {
    return f(a)
}

protocol WrapType {
    typealias T
    var value:T {get set}
}

class Weak<T where T: AnyObject>:WrapType {
    weak var value : T?
    init (_ value: T) {self.value = value}
}

class Box<T>:WrapType {
    var value : T
    init (_ value: T) {self.value = value}
}
