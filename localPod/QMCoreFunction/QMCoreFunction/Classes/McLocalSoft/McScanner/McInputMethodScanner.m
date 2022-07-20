//
//  McInputMethodScanner.m
//  McSoftwareScanner
//
//  
//  Copyright (c) 2013年 haotan. All rights reserved.
//

#import "McInputMethodScanner.h"

@implementation McInputMethodScanner

- (NSArray *)scanPaths
{
    return  @[@"/Library/Input Methods",
              [@"~/Library/Input Methods" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagInputMethod;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"app"])
    {
        return YES;
    }
    
    return NO;
}

@end
