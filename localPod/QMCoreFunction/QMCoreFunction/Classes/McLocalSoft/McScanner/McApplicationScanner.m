//
//  McApplicationScanner.m
//  McSoftware
//
//  Created by developer on 10/17/12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McApplicationScanner.h"
#import <dlfcn.h>

@implementation McApplicationScanner

//extern OSStatus _LSCopyAllApplicationURLs(CFArrayRef * array);

- (NSArray *)scanPaths
{
    static OSStatus (*QMCopyAllApplicationURLs)(CFArrayRef * array) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        QMCopyAllApplicationURLs = dlsym(RTLD_DEFAULT, "_LSCopyAllApplicationURLs");
    });
    
    if (QMCopyAllApplicationURLs)
    {
        NSMutableArray *scanPaths = [[NSMutableArray alloc] init];
        CFArrayRef appURLs = NULL;
        QMCopyAllApplicationURLs(&appURLs);
        
        for (CFIndex idx=0; idx<CFArrayGetCount(appURLs); idx++)
        {
            CFURLRef appURL = CFArrayGetValueAtIndex(appURLs, idx);
            NSString *appPath = (__bridge_transfer NSString *)CFURLCopyPath(appURL);
            appPath = [appPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if ([self fileVaild:appPath])
            {
                //去除掉末尾的"/"符号
                while (appPath.length>0 && [appPath hasSuffix:@"/"])
                {
                    appPath = [appPath substringWithRange:NSMakeRange(0, appPath.length-1)];
                }
                [scanPaths addObject:appPath];
            }
        }
        CFRelease(appURLs);
        return scanPaths;
    }
    
    return  @[@"/Applications",
              [@"~/Applications" stringByExpandingTildeInPath],
              [@"~/Downloads" stringByExpandingTildeInPath],
              [@"~/Desktop" stringByExpandingTildeInPath],
              [@"~/Documents" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagApplication;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {        
        return NO;
    }
    
    //只处理用户目录和Applications目录
    if (![filePath hasPrefix:NSHomeDirectory()] && ![filePath hasPrefix:@"/Applications/"])
        return NO;
    
    //垃圾箱中软件不处理
    if ([filePath hasPrefix:[NSHomeDirectory() stringByAppendingString:@"/.Trash/"]])
        return NO;
    
    //Library中的软件不处理
    if ([filePath hasPrefix:[NSHomeDirectory() stringByAppendingString:@"/Library/"]])
        return NO;
    
    //不处理/Applications/CrossOver下的Window兼容软件
    if ([filePath hasPrefix:[NSHomeDirectory() stringByAppendingString:@"/Applications/CrossOver/"]])
        return NO;
        
    //不处理build目录下的软件
    if ([filePath rangeOfString:@"/build/" options:NSCaseInsensitiveSearch].length > 0)
        return NO;
    
    //不处理Parallels虚拟机中的软件
    if ([filePath rangeOfString:@"\\/Applications \\(Parallels\\)\\/" options:NSRegularExpressionSearch].length > 0)
        return NO;
    
    //包下面的子程序不处理(逐层检测父路径是否为Package)
    BOOL isSubApp = NO;
    NSString *parentPath = [filePath stringByDeletingLastPathComponent];
    while ([parentPath.pathComponents count] > 2)
    {
        if ([parentPath.pathExtension length] > 0 && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:parentPath])
        {
            isSubApp = YES;
            break;
        }
        parentPath = [parentPath stringByDeletingLastPathComponent];
    }
    if (isSubApp)
        return NO;
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"app"])
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)bundleVaild:(NSBundle *)bundle
{
    if (![super bundleVaild:bundle])
        return NO;
    
    NSString *bundleIdentifier = bundle.bundleIdentifier;
    
    //不处理CrossOver的windows软件
    if ([bundleIdentifier hasPrefix:@"com.codeweavers.CrossOverHelper"])
        return NO;
    
    //不处理VMWare的Windows软件
    if ([bundleIdentifier hasPrefix:@"com.vmware.proxyApp"])
        return NO;
    
    //不处理parallels的windows软件
    if ([bundleIdentifier hasPrefix:@"com.parallels.ApplicationGroupBridge"] ||
        [bundleIdentifier hasPrefix:@"com.parallels.winapp"])
        return NO;
    
    return YES;
}

@end
