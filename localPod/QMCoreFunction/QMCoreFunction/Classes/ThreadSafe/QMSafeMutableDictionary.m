//
//  QMSafeMutableDictionary.m
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMSafeMutableDictionary.h"

@interface QMSafeMutableDictionary ()
{
    NSRecursiveLock *_safeLock;
    CFMutableDictionaryRef _dictionary;
}
@end

@implementation QMSafeMutableDictionary

- (id)init
{
    self = [super init];
    if (self) {
        _safeLock = [[NSRecursiveLock alloc] init];
        _dictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                &kCFTypeDictionaryKeyCallBacks,
                                                &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self)
    {
        _safeLock = [[NSRecursiveLock alloc] init];
        _dictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, numItems,
                                                &kCFTypeDictionaryKeyCallBacks,
                                                &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (id)initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt
{
    self = [self init];
    if (self)
    {
        for (NSInteger idx = 0; idx < cnt; idx++)
        {
            CFDictionaryAddValue(_dictionary, (__bridge CFTypeRef)(keys[idx]), (__bridge CFTypeRef)(objects[idx]));
        }
    }
    return self;
}

- (void)dealloc
{
    if (_dictionary)
    {
        CFRelease(_dictionary);
        _dictionary = NULL;
    }
}

- (NSUInteger)count
{
    [_safeLock lock];
    NSUInteger count = CFDictionaryGetCount(_dictionary);
    [_safeLock unlock];
    return count;
}

- (id)objectForKey:(id)aKey
{
    if (!aKey)
        return nil;
    
    [_safeLock lock];
    id result = (__bridge id)CFDictionaryGetValue(_dictionary, (__bridge CFTypeRef)(aKey));
    [_safeLock unlock];
    return result;
}

- (NSEnumerator *)keyEnumerator
{
    [_safeLock lock];
    id result = [(__bridge id)_dictionary keyEnumerator];
    [_safeLock unlock];
    return result;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    if (!anObject || !aKey)
        return;
    
    [_safeLock lock];
    CFDictionarySetValue(_dictionary, (__bridge CFTypeRef)aKey, (__bridge CFTypeRef)anObject);
    [_safeLock unlock];
}

- (void)removeObjectForKey:(id)aKey
{
    if (!aKey)
        return;
    
    [_safeLock lock];
    CFDictionaryRemoveValue(_dictionary, (__bridge CFTypeRef)aKey);
    [_safeLock unlock];
}

#pragma mark Optional

- (void)removeAllObjects
{
    [_safeLock lock];
    CFDictionaryRemoveAllValues(_dictionary);
    [_safeLock unlock];
}

- (NSArray *)allKeys
{
    [_safeLock lock];
    NSUInteger count = CFDictionaryGetCount(_dictionary);
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count];
    NSEnumerator *enumerator = [(__bridge id)_dictionary keyEnumerator];
    id key = nil;
    while (key = [enumerator nextObject])
    {
        [result addObject:key];
    }
    [_safeLock unlock];
    return [NSArray arrayWithArray:result];
}

- (NSArray *)allValues
{
    [_safeLock lock];
    NSUInteger count = CFDictionaryGetCount(_dictionary);
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count];
    NSEnumerator *enumerator = [(__bridge id)_dictionary keyEnumerator];
    id key = nil;
    while (key = [enumerator nextObject])
    {
        id value = (__bridge id)CFDictionaryGetValue(_dictionary, (__bridge CFTypeRef)(key));
        [result addObject:value];
    }
    [_safeLock unlock];
    return [NSArray arrayWithArray:result];
}

// NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    [_safeLock lock];
    NSUInteger result = [(__bridge NSMutableDictionary*)_dictionary countByEnumeratingWithState:state objects:buffer count:len];
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
