//
//  QMScanFileSizeCacheManager.m
//  LemonClener
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "QMScanFileSizeCacheManager.h"

@interface QMScanFileSizeCacheManager ()

@property (nonatomic, strong) NSMutableDictionary *mutableDict;

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

- (void)start {
    self.mutableDict = [[NSMutableDictionary alloc] init];
}

- (void)end {
    self.mutableDict = nil;
}

- (BOOL)hasCachedFileSizeWithPath:(NSString *)path {
    if (![path isKindOfClass:NSString.class]) {
        return NO;
    }
    
    if (!self.mutableDict) {
        return NO;
    }
    
    return self.mutableDict[path] != nil;
}

- (uint64)getCachedFileSizeWithPath:(NSString *)path {
    if (![path isKindOfClass:NSString.class]) {
        return 0;
    }
    return [self.mutableDict[path] unsignedLongLongValue];
}

- (BOOL)cacheFileAtPath:(NSString *)path withSize:(unsigned long long)size {
    if (![path isKindOfClass:NSString.class]) {
        return NO;
    }
    if (!self.mutableDict) {
        return NO;
    }
    self.mutableDict[path] = [NSNumber numberWithUnsignedLongLong:size];
    return YES;
}

@end
