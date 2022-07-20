//
//  QMDataCenter.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMDataCenter.h"
#import "QMCryptUtility.h"

#define kQMDataCenterSaveKey @"LemonConfiguration"
NSString * const QMDataCenterDidChangeNotification = @"QMDataCenterDidChangeNotification";

@interface QMDataCenter()
{
    NSLock *lock;
    NSMutableDictionary *centerInfo;
}
@end

@implementation QMDataCenter

+ (QMDataCenter *)defaultCenter
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
        NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:kQMDataCenterSaveKey];
        if (info && [info isKindOfClass:[NSDictionary class]])
        {
            centerInfo = [info mutableCopy];
        }else
        {
            centerInfo = [[NSMutableDictionary alloc] init];
        }
        
        lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString *)haskKey:(NSString *)aKey
{
    if (!aKey)
        return nil;
    return [QMCryptUtility hashString:aKey with:QMHashKindSha1];
}

- (void)postNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:QMDataCenterDidChangeNotification object:self];
    });
}

//Getting Default Values
- (BOOL)boolForKey:(NSString *)aKey
{
    return [[self stringForKey:aKey] boolValue];
}

- (double)doubleForKey:(NSString *)aKey
{
    return [[self stringForKey:aKey] doubleValue];
}

- (NSInteger)integerForKey:(NSString *)aKey
{
    return [[self stringForKey:aKey] integerValue];
}

- (NSString *)stringForKey:(NSString *)aKey
{
    NSData *data = [self dataForKey:aKey];
    if (!data)
        return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)dataForKey:(NSString *)aKey
{
    if (!aKey)
        return nil;
    NSString *hashKey = [self haskKey:aKey];
    if (!hashKey)
        return nil;
    
    [lock lock];
    NSData *data = [centerInfo objectForKey:hashKey];
    [lock unlock];
    
    return data;
}

- (id)objectForKey:(NSString *)aKey
{
    NSData *data = [self dataForKey:aKey];
    if (!data)
        return nil;
    
    id value = nil;
    @try {
        value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        value = nil;
    }
    return value;
}

- (NSArray *)arrayForKey:(NSString *)aKey
{
    id value = [self objectForKey:aKey];
    if ([value isKindOfClass:[NSArray class]])
        return value;
    return nil;
}

//Setting Default Values
- (BOOL)setBool:(BOOL)value forKey:(NSString *)aKey
{
    return [self setString:[NSString stringWithFormat:@"%d",value] forKey:aKey];
}

- (BOOL)setInteger:(NSInteger)value forKey:(NSString *)aKey
{
    return [self setString:[NSString stringWithFormat:@"%ld",value] forKey:aKey];
}

- (BOOL)setDouble:(double)value forKey:(NSString *)aKey
{
    return [self setString:[NSString stringWithFormat:@"%f",value] forKey:aKey];
}

- (BOOL)setString:(NSString *)value forKey:(NSString *)aKey
{
    if (!aKey)
        return NO;
    if (!value)
        return [self removeValueForKey:aKey];
    
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data)
        return NO;
    return [self setData:data forKey:aKey];
}

- (BOOL)setData:(NSData *)value forKey:(NSString *)aKey
{
    if (!aKey)
        return NO;
    if (!value)
        return [self removeValueForKey:aKey];
    NSString *hashKey = [self haskKey:aKey];
    if (!hashKey)
        return NO;
    
    [lock lock];
    [centerInfo setObject:value forKey:hashKey];
    [[NSUserDefaults standardUserDefaults] setObject:centerInfo forKey:kQMDataCenterSaveKey];
    [lock unlock];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self postNotification];
    
    return YES;
}

- (BOOL)setObject:(id)value forKey:(NSString *)aKey
{
    if (!aKey)
        return NO;
    if (!value)
        return [self removeValueForKey:aKey];
    
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:value];
    }
    @catch (NSException *exception) {
        return NO;
    }
    if (!data)
        return NO;
    return [self setData:data forKey:aKey];
}

- (BOOL)valueExistsForKey:(NSString *)aKey
{
    if (!aKey)
        return NO;
    NSString *hashKey = [self haskKey:aKey];
    if (!hashKey)
        return NO;
    
    [lock lock];
    BOOL exists = ([centerInfo objectForKey:hashKey]!=nil);
    [lock unlock];
    return exists;
}

- (BOOL)removeValueForKey:(NSString *)aKey
{
    if (!aKey)
        return NO;
    NSString *hashKey = [self haskKey:aKey];
    if (!hashKey)
        return NO;
    
    [lock lock];
    [centerInfo removeObjectForKey:hashKey];
    [[NSUserDefaults standardUserDefaults] setObject:centerInfo forKey:kQMDataCenterSaveKey];
    [lock unlock];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self postNotification];
    
    return YES;
}

@end
