//
//  QMSafeMutableArray.m
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMSafeMutableArray.h"

@interface QMSafeMutableArray()
{
    CFMutableArrayRef _array;
    NSRecursiveLock *_safeLock;
}
@end

@implementation QMSafeMutableArray

- (id)init
{
    self = [super init];
    if (self) {
        _safeLock = [[NSRecursiveLock alloc] init];
        _array = CFArrayCreateMutable(kCFAllocatorDefault, 0,  &kCFTypeArrayCallBacks);
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self)
    {
        _safeLock = [[NSRecursiveLock alloc] init];
        _array = CFArrayCreateMutable(kCFAllocatorDefault, numItems,  &kCFTypeArrayCallBacks);
    }
    return self;
}

- (void)dealloc
{
    if (_array)
    {
        CFRelease(_array);
        _array = NULL;
    }
}

- (NSUInteger)count
{
    [_safeLock lock];
    NSUInteger result = CFArrayGetCount(_array);
    [_safeLock unlock];
    return result;
}

- (id)objectAtIndex:(NSUInteger)index
{
    [_safeLock lock];
    NSUInteger count = CFArrayGetCount(_array);
    id result = index<count ? (__bridge id)CFArrayGetValueAtIndex(_array, index) : nil;
    [_safeLock unlock];
    return result;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if (!anObject)
        return;
    
    [_safeLock lock];
    NSUInteger count = CFArrayGetCount(_array);
    if (index > count) {
        index = count;
    }
    CFArrayInsertValueAtIndex(_array, index, (__bridge CFTypeRef)anObject);
    [_safeLock unlock];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_safeLock lock];
    NSUInteger count = CFArrayGetCount(_array);
    if (index < count) {
        CFArrayRemoveValueAtIndex(_array, index);
    }
    [_safeLock unlock];
}

- (void)addObject:(id)anObject
{
    if (!anObject)
        return;
    
    [_safeLock lock];
    CFArrayAppendValue(_array, (__bridge CFTypeRef)anObject);
    [_safeLock unlock];
}

- (void)removeLastObject
{
    [_safeLock lock];
    NSUInteger count = CFArrayGetCount(_array);
    if (count > 0) {
        CFArrayRemoveValueAtIndex(_array, count-1);
    }
    [_safeLock unlock];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    if (!anObject)
        return;
    
    [_safeLock lock];
    NSUInteger count = CFArrayGetCount(_array);
    if (index < count) {
        CFArraySetValueAtIndex(_array, index, (__bridge CFTypeRef)anObject);
    }
    [_safeLock unlock];
}

#pragma mark Optional

- (void)removeObject:(id)anObject
{
    [_safeLock lock];
    [(__bridge NSMutableArray *)_array removeObject:anObject];
    [_safeLock unlock];
}

- (void)removeAllObjects
{
    [_safeLock lock];
    CFArrayRemoveAllValues(_array);
    [_safeLock unlock];
}

- (NSUInteger)indexOfObject:(id)anObject
{
    if (!anObject)
        return NSNotFound;
    
    [_safeLock lock];
    NSUInteger count = CFArrayGetCount(_array);
    NSUInteger result = CFArrayGetFirstIndexOfValue(_array, CFRangeMake(0, count), (__bridge CFTypeRef)(anObject));
    [_safeLock unlock];
    return result;
}

- (void)addObjectsFromArray:(NSArray *)otherArray
{
    [_safeLock lock];
    for (id anObject in otherArray)
    {
        CFArrayAppendValue(_array, (__bridge CFTypeRef)anObject);
    }
    [_safeLock unlock];
}

- (void)removeObjectsInArray:(NSArray *)otherArray
{
    [_safeLock lock];
    [(__bridge NSMutableArray *)_array removeObjectsInArray:otherArray];
    [_safeLock unlock];
}

// NSPredicateSupport

- (NSArray *)filteredArrayUsingPredicate:(NSPredicate *)predicate
{
    [_safeLock lock];
    id result = [super filteredArrayUsingPredicate:predicate];
    [_safeLock unlock];
    return result;
}

- (void)filterUsingPredicate:(NSPredicate *)predicate
{
    [_safeLock lock];
    [super filterUsingPredicate:predicate];
    [_safeLock unlock];
}

// NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    [_safeLock lock];
    NSUInteger result = [(__bridge NSMutableArray *)_array countByEnumeratingWithState:state objects:buffer count:len];
    [_safeLock unlock];
    return result;
}

#pragma mark NSLocking

- (void)lock
{
    [_safeLock lock];
}

- (void)unlock
{
    [_safeLock unlock];
}

@end
