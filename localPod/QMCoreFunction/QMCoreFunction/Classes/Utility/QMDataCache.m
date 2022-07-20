//
//  QMDataCache.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMDataCache.h"
#import "QMCryptUtility.h"

@interface QMDataCache ()
{
    NSString *cachePath;
}
@end

@implementation QMDataCache

+ (QMDataCache *)sharedCache
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
        cachePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:NULL error:NULL];
        }
    }
    return self;
}

- (NSString *)haskKey:(NSString *)aKey
{
    if (!aKey)
        return nil;
    return [QMCryptUtility hashString:aKey with:QMHashKindSha1];
}

- (NSData *)dataForKey:(NSString *)aKey
{
    if (!aKey)
        return nil;
    NSString *fileName = [self haskKey:aKey];
    if (!fileName)
        return nil;
    NSString *filePath = [cachePath stringByAppendingPathComponent:fileName];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    return data;
}

- (void)setData:(NSData *)data forKey:(NSString *)aKey
{
    if (!data || !aKey)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *fileName = [self haskKey:aKey];
        if (!fileName)
            return;
        NSString *filePath = [cachePath stringByAppendingPathComponent:fileName];
        [data writeToFile:filePath atomically:YES];
    });
}

@end
