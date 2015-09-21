//
//  Flow+UIKit.swift
//  Flowless
//
//  Created by Mikhail Vroubel on 9/21/15.
//  Copyright © 2015 Mikhail Vroubel. All rights reserved.
//

import UIKit

extension Flow {
    public class func source(source:UIControl, events:UIControlEvents) -> Flow<UIControl> {
        return Flow<UIControl> { flow in
            weak var o = source.observeEvents(events) {flow.put($0)}
            flow.done.addOutput {_ in o?.cancel()}
        }
    }
    public class func sourceSender(source:UIGestureRecognizer) -> Flow<UIGestureRecognizer> {
        return Flow<UIGestureRecognizer> { flow in
            weak var o = source.observeSender {flow.put($0)}
            flow.done.addOutput {_ in o?.cancel()}
        }
    }
}