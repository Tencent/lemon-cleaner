//
//  NSBundle+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSBundle+Extension.h"

@implementation NSBundle(NoCache)

- (id)infoValueForKey:(NSString *)key
{
    if (!key)
        return nil;
    
    NSDictionary *infoDictionary = nil;
    NSString *infoPath = [self.bundlePath stringByAppendingString:@"/Contents/Info.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath])
        infoDictionary = [[NSDictionary alloc] initWithContentsOfFile:infoPath];
    
    if (!infoDictionary)
        infoDictionary = [self infoDictionary];
    
    return infoDictionary[key];
}

- (NSString *)shortVersionString
{
    return [self infoValueForKey:@"CFBundleShortVersionString"];
}

@end
