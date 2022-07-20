//
//  QMConditionLock.m
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMConditionLock.h"
#import "QMSafeMutableDictionary.h"

@interface QMCountLock : NSLock
@property (nonatomic, assign) uint64_t count;
@end

@implementation QMCountLock
@synthesize count;
@end

@interface QMConditionLock ()
{
    NSMutableDictionary *_lockInfo;
}
@end

@implementation QMConditionLock

+ (QMConditionLock *)sharedLock
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _lockInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)lockForKey:(id<NSCopying>)key
{
    if (!key)
        return;
    
    QMCountLock *lock = nil;
    
    @synchronized(self)
    {
        lock = [_lockInfo objectForKey:key];
        if (!lock)
        {
            lock = [[QMCountLock alloc] init];
            [_lockInfo setObject:lock forKey:key];
        }
        lock.count++;
    }
    
    [lock lock];
}

- (void)unLockForKey:(id<NSCopying>)key
{
    if (!key)
        return;
    
    QMCountLock *lock = nil;
    
    @synchronized(self)
    {
        lock = [_lockInfo objectForKey:key];
        if (!lock)
            return;
        
        if (--lock.count == 0)
            [_lockInfo removeObjectForKey:key];
    }
    
    [lock unlock];
}

@end
