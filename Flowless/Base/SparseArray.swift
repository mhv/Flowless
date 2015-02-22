//
//  SparseArray.swift
//  Signal
//
//  Created by Mikhail Vroubel on 07/02/2015.
//
//

import Foundation

struct SparseArray<T> : CollectionType {
    typealias Element = (Int, T)
    typealias Index = DictionaryIndex<Int, T>
    var indices = NSMutableIndexSet()
    var accessor = [Int: T]()
    var startIndex: Index {
        return accessor.startIndex
    }
    
    var endIndex: Index {
        return accessor.endIndex
    }
    
    subscript (position: Index) -> Element {
        return accessor[position]
    }
    
    func generate() -> GeneratorOf<Element> {
        var last = indices.firstIndex - 1
        return GeneratorOf<Element> {
            last = self.indices.indexGreaterThanIndex(last)
            return last != NSNotFound ? (last, self.accessor[last]!) : nil
        }
    }
    
    subscript (idx:Int)->T? {
        get {
            return accessor[idx]
        }
        set (value) {
            if let v = value {
                append(v, index: idx)
            } else {
                removeAtIndex(idx)
            }
        }
    }
    
    mutating func append(value:T, index:Int = 0)->Int {
        var next = max(indices.count > 0 ? indices.lastIndex + 1 : 0, index)
        indices.addIndex(next)
        accessor[index] = value
        return next
    }
    
    mutating func removeAtIndex(index: Int) {
        accessor[index] = nil
        indices.removeIndex(index)
    }
}