//
//  Operation.swift
//  MVKit
//
//  Created by Mikhail Vroubel on 07/06/2014.
//  Copyright (c) 2014 Mikhail Vroubel. All rights reserved.
//

import Foundation


extension NSOperationQueue {
    class func async(blocks:[()->Void]? = nil, finish:()->Void = {})->NSBlockOperation {
        return NSOperationQueue.mainQueue().async(blocks:blocks, finish: finish)
    }
    func async(blocks:[()->Void]? = nil, finish:()->Void = {})->NSBlockOperation {
        let fin = NSBlockOperation {finish()}
        if let array = blocks {
            let ops = array.map {NSBlockOperation(block:$0)}
            ops.map {fin.addDependency($0)}
            self.addOperations(ops, waitUntilFinished:false)
        }
        self.addOperation(fin)
        return fin
    }
}

extension dispatch_queue_t {
    class func async(blocks:[()->Void]? = nil, finish:()->Void = {})->() {
        dispatch_get_main_queue().async(blocks: blocks, finish: finish)
    }
    func async(blocks:[()->Void]? = nil, finish:()->Void = {})->() {
        if (blocks != nil) {
            blocks!.map {dispatch_async(self, $0)}
            dispatch_barrier_async(self, finish)
        } else {
            dispatch_async(self, finish)
        }
    }
}

