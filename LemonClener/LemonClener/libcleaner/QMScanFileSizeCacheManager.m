//
//  QMScanFileSizeCacheManager.m
//  LemonClener
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "QMScanFileSizeCacheManager.h"
#import <pthread.h>

@interface QMScanFileSizeCacheManager ()

@property (nonatomic, strong) NSMutableDictionary *mutableDict;
@property (nonatomic, assign) pthread_rwlock_t rwlock;  // 读写锁

@end

@implementation QMScanFileSizeCacheManager

+ (QMScanFileSizeCacheManager *)manager {
    static QMScanFileSizeCacheManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[QMScanFileSizeCacheManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        // 初始化读写锁
        int result = pthread_rwlock_init(&_rwlock, NULL);
        if (result != 0) {
            NSLog(@"QMScanFileSizeCacheManager: Failed to initialize rwlock, error: %d", result);
            return nil;
        }
    }
    return self;
}

- (void)start {
    pthread_rwlock_wrlock(&_rwlock);
    self.mutableDict = [[NSMutableDictionary alloc] init];
    pthread_rwlock_unlock(&_rwlock);
}

- (void)end {
    pthread_rwlock_wrlock(&_rwlock);
    self.mutableDict = nil;
    pthread_rwlock_unlock(&_rwlock);
}

- (BOOL)hasCachedFileSizeWithPath:(NSString *)path {
    if (![path isKindOfClass:NSString.class]) {
        return NO;
    }
    
    pthread_rwlock_rdlock(&_rwlock);
    BOOL result = NO;
    if (self.mutableDict) {
        result = self.mutableDict[path] != nil;
    }
    pthread_rwlock_unlock(&_rwlock);
    
    return result;
}

- (uint64_t)getCachedFileSizeWithPath:(NSString *)path {
    if (![path isKindOfClass:NSString.class]) {
        return 0;
    }
    
    pthread_rwlock_rdlock(&_rwlock);
    uint64_t result = 0;
    if (self.mutableDict && self.mutableDict[path]) {
        result = [self.mutableDict[path] unsignedLongLongValue];
    }
    pthread_rwlock_unlock(&_rwlock);
    
    return result;
}

- (void)cacheFileAtPath:(NSString *)path withSize:(unsigned long long)size {
    if (![path isKindOfClass:NSString.class]) {
        return;
    }
    
    pthread_rwlock_wrlock(&_rwlock);
    if (self.mutableDict) {
        self.mutableDict[path] = [NSNumber numberWithUnsignedLongLong:size];
    }
    pthread_rwlock_unlock(&_rwlock);
}

@end
