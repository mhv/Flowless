//
//  Flow+UIKit.swift
//  Flowless
//
//  Created by Mikhail Vroubel on 9/21/15.
//  Copyright © 2015 Mikhail Vroubel. All rights reserved.
//

import UIKit
import Beholder
import Utils

extension Flow {
    public class func source(_ source:UIControl, events:UIControlEvents) -> Flow<UIControl> {
        return Flow<UIControl> { flow in
            weak var o = source.observeEvents(events) {flow.put($0)}
            _ = flow.done.addAction {_ in o?.finish()}
        }
    }
    public class func sourceSender(_ source:UIGestureRecognizer) -> Flow<UIGestureRecognizer> {
        return Flow<UIGestureRecognizer> { flow in
            weak var o = source.observeSender {flow.put($0)}
            _ = flow.done.addAction {_ in o?.finish()}
        }
    }
}
