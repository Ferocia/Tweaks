//
//  WeakMutableSet.h
//  FBTweak
//
//  Created by Josh Bassett on 29/04/2014.
//

#import <Foundation/Foundation.h>

@interface NSObject (MDeallocObserver)

- (void)addDeallocObserverBlock:(void (^)(void))block;
- (void)addDeallocObserverWithKey:(id<NSCopying>)key block:(void (^)(void))block;
- (void)removeDeallocObserverForKey:(id<NSCopying>)key;

@end

@interface WeakMutableSet : NSMutableSet
@end
