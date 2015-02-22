//
//  Lock.swift
//  Signal
//
//  Created by Mikhail Vroubel on 20/11/2014.
//
//

import Foundation

// non-recursive lock

class Lock {
    private var spinlock:OSSpinLock = OS_SPINLOCK_INIT
    
    func try()->(Bool) {
        return withUnsafeMutablePointer(&spinlock, OSSpinLockTry)
    }
    
    func lock() {
        withUnsafeMutablePointer(&spinlock, OSSpinLockLock)
    }
    
    func unlock() {
        withUnsafeMutablePointer(&spinlock, OSSpinLockUnlock)
    }
    
    func locked<T>(fun:()->T) -> T {
        var result:T? = nil
        withUnsafeMutablePointer(&spinlock) {(lock:UnsafeMutablePointer<OSSpinLock>)->() in
            OSSpinLockLock(lock)
            result = fun()
            OSSpinLockUnlock(lock)
        }
        return result!
    }
}

class RecursiveLock {
    private var internalLock = Lock()
    private var spinlock:OSSpinLock = OS_SPINLOCK_INIT
    private var thread:NSThread? = nil
    private var count:UInt = 0
    func lock() {
        internalLock.locked {
            withUnsafeMutablePointer(&self.spinlock) {(lock:UnsafeMutablePointer<OSSpinLock>)->() in
                if (!OSSpinLockTry(lock)) {
                    if self.thread != NSThread.currentThread() {
                        OSSpinLockLock(lock)
                    }
                }
                self.count++
                if self.thread == nil {
                    self.thread = NSThread.currentThread()
                }
            }
        }
    }
    func unlock() {
        internalLock.locked {
            withUnsafeMutablePointer(&self.spinlock) {(lock:UnsafeMutablePointer<OSSpinLock>)->() in
                self.count--
                if self.count == 0 {
                    self.thread = nil
                    OSSpinLockUnlock(lock)
                }
            }
        }
    }
    func locked(fun:()->()) {
        withUnsafeMutablePointer(&spinlock) {(lock:UnsafeMutablePointer<OSSpinLock>)->() in
            self.lock()
            fun()
            self.unlock()
        }
    }
}

