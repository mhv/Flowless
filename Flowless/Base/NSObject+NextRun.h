//
//  NSObject+NextRun.h
//  Signal
//
//  Created by Mikhail Vroubel on 07/02/2015.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (NextRun)

- (void)nextRun:(void (^)())block;

@end

@interface OwneeBase : NSObject
@property (nonatomic, unsafe_unretained) id unsafeOwner; // XXX for KVO magic of horrors
@end
