//
//  WeakMutableSet.m
//  FBTweak
//
//  Created by Josh Bassett on 29/04/2014.
//

#import "WeakMutableSet.h"
#import <objc/runtime.h>

@interface DeallocObserver : NSObject

@property (nonatomic, strong) NSMutableDictionary *blocks;

@end

@implementation DeallocObserver

- (id)init {
  self = [super init];
  if (self) {
    _blocks = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)dealloc {
  for (id block in _blocks.allValues) {
    ((void (^)(void))block)();
  }
}

@end

static char observerKey;

@implementation NSObject (DeallocObserver)

- (void)addDeallocObserverBlock:(void (^)(void))block {
  [self addDeallocObserverWithKey:block block:block];
}

- (void)addDeallocObserverWithKey:(id<NSCopying>)key block:(void (^)(void))block {
  DeallocObserver *observer = objc_getAssociatedObject(self, &observerKey);
  if (!observer) {
    observer = [DeallocObserver new];
    objc_setAssociatedObject(self, &observerKey, observer, OBJC_ASSOCIATION_RETAIN);
  }
  [observer.blocks setObject:block forKey:key];
}

- (void)removeDeallocObserverForKey:(id<NSCopying>)key {
  DeallocObserver *observer = objc_getAssociatedObject(self, &observerKey);
  [observer.blocks removeObjectForKey:key];
}

@end

@implementation WeakMutableSet {
  NSMutableSet *_nonretainedSet;
}

- (id)initWithCapacity:(NSUInteger)numItems {
  self = [super init];
  if (self) {
    const CFSetCallBacks callbacks = {0, NULL, NULL, CFCopyDescription, CFEqual};
    _nonretainedSet = (id)CFBridgingRelease(CFSetCreateMutable(NULL, numItems, &callbacks));
  }
  return self;
}

- (NSUInteger)count {
  return _nonretainedSet.count;
}

- (id)member:(id)object {
  return [_nonretainedSet member:object];
}

- (NSEnumerator *)objectEnumerator {
  return _nonretainedSet.objectEnumerator;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
  return [_nonretainedSet countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)addObject:(id)object {
  [_nonretainedSet addObject:object];
  __unsafe_unretained id unretainedobj = object;
  __weak NSMutableSet *set = _nonretainedSet;
  [object addDeallocObserverWithKey:[NSValue valueWithNonretainedObject:object] block:^{
    [set removeObject:unretainedobj];
  }];
}

- (void)removeObject:(id)object {
  [_nonretainedSet removeObject:object];
  [object removeDeallocObserverForKey:[NSValue valueWithNonretainedObject:object]];
}

@end
