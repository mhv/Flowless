//
//  State.swift
//  MVKit
//
//  Created by Mikhail Vroubel on 07/06/2014.
//  Copyright (c) 2014 Mikhail Vroubel. All rights reserved.
//

import Foundation

protocol IState {
    var name:String {get}
    var push:((Stater)->Void)? {get}
    var pop:((Stater)->Void)? {get}
    
}
func ==(lhs: IState, rhs: IState) -> Bool {
    return lhs.name == rhs.name
}

struct State:IState {
    let name:String
    let push:((Stater)->Void)?
    let pop:((Stater)->Void)?
}

class Stater {
    var state:[IState] = [] {
        willSet {
            var firstDiff = 0
            var oldValue = state
            while (firstDiff < oldValue.endIndex && firstDiff < newValue.endIndex && oldValue[firstDiff] == newValue[firstDiff]) {
                firstDiff++
            }
            if (firstDiff < oldValue.count) {
                for i in oldValue.endIndex...firstDiff {pop()}
            }
            if (firstDiff < newValue.count) {
                for i in firstDiff...newValue.endIndex {push(newValue[i])}
            }
        }
    }
    func pop()->IState {
        self.peek().pop?(self)
        return state.removeLast()
    }
    func push(s:IState) {
        state.append(s)
        s.push?(self)
    }
    func peek()->IState {
        return state[state.endIndex]
    }
}
func += (inout left:Stater, right:IState) {
    left.push(right)
}
postfix func -- (inout left:Stater) {
    left.pop()
}
infix operator <> {}
func <> (inout left:Stater, right:[IState]) {
    left.state = right
}

