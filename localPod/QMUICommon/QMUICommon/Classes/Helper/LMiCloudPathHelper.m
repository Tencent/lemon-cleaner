//
//  LMiCloudPathHelper.m
//  LemonDuplicateFile
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LMiCloudPathHelper.h"

#define kicloudContanierPath [@"~/Library/Mobile Documents" stringByExpandingTildeInPath]
#define kicloudPath [@"~/Library/Mobile Documents/com~apple~CloudDocs" stringByExpandingTildeInPath]


@implementation LMiCloudPathHelper

+ (BOOL)isICloudSubPath:(NSString *)path{
    if (!path){
        return NO;
    }
    
    if ([path hasPrefix:kicloudContanierPath]){
        return YES;
    }
    
    return NO;
}

+ (BOOL)isICloudContanierPath:(NSString *)path{
    if (!path){
        return NO;
    }
    
    if ([path isEqualToString:kicloudContanierPath]){
        return YES;
    }
    
    return NO;
}

+ (BOOL)isICloudPath:(NSString *)path{
    if (!path){
        return NO;
    }
    
    if ([path isEqualToString:kicloudPath]){
        return YES;
    }
    
    return NO;
}

+ (NSString *)getICloudContainerPath{
    return kicloudContanierPath;
}

+ (NSString *)getICloudPath{
    return kicloudPath;
}

+ (NSString *)getICloudPathdisplayName{
    return [[NSFileManager defaultManager] displayNameAtPath: kicloudPath];
}


@end
