//
//  NSObject+NextRun.m
//  Signal
//
//  Created by Mikhail Vroubel on 07/02/2015.
//
//

#import "NSObject+NextRun.h"

@implementation NSObject (NextRun)

- (void)nextRun:(void (^)())block {
    [self performSelector:@selector(_nextRun:)withObject:block afterDelay:0];
}

- (void)_nextRun:(void (^)())block {
    block();
}

@end

@implementation OwneeBase
@end
