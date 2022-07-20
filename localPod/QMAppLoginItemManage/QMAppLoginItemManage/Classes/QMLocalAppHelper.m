//
//  QMLocalAppHelper.m
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "QMLocalAppHelper.h"
#import <dlfcn.h>
#import <AppKit/NSWorkspace.h>
#import <sys/stat.h>

@interface QMLocalAppHelper()

/**
 app 扫描目录
 */
@property NSArray *appScanPathArray;

///Save local app
@property NSMutableArray<QMLocalApp *> *localAppArray;

@end

///app helper
@implementation QMLocalAppHelper

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static QMLocalAppHelper *instance;
    dispatch_once(&onceToken, ^{
        instance = [[QMLocalAppHelper alloc] init];
        [instance initData];
    });
    return instance;
}

- (void)initData {
    self.appScanPathArray =  @[@"/Applications",
    [@"~/Applications" stringByExpandingTildeInPath],
    [@"~/Downloads" stringByExpandingTildeInPath],
    [@"~/Desktop" stringByExpandingTildeInPath],
    [@"~/Documents" stringByExpandingTildeInPath]];
    self.localAppArray = [[NSMutableArray alloc] init];
    NSArray *appPathArray = [self getAppsByEnumDir];
    for (NSString *path in appPathArray) {
        QMLocalApp *localApp = [[QMLocalApp alloc] initWithBundlePath:path];
        [self.localAppArray addObject:localApp];
    }
}

- (NSArray<QMLocalApp *> *)getLocalAppData {
    return self.localAppArray;
}

- (NSArray<NSString*> *)getAppsFromSystem {
    NSDate *date = [NSDate date];
    static OSStatus (*QMCopyAllApplicationURLs)(CFArrayRef * array) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        QMCopyAllApplicationURLs = dlsym(RTLD_DEFAULT, "_LSCopyAllApplicationURLs");
    });
    if (!QMCopyAllApplicationURLs) {
        return nil;
    }
    NSMutableArray<NSString*> *scanPaths = [[NSMutableArray alloc] init];
    CFArrayRef appURLs = NULL;
    QMCopyAllApplicationURLs(&appURLs);
    for (CFIndex idx=0; idx<CFArrayGetCount(appURLs); idx++)
    {
        CFURLRef appURL = CFArrayGetValueAtIndex(appURLs, idx);
        NSString *appPath = (__bridge_transfer NSString *)CFURLCopyPath(appURL);
        appPath = [appPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"appPath : %@", appPath);
        
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
    NSTimeInterval interval = [date timeIntervalSinceNow];
    NSLog(@"%s app count: %lu",__FUNCTION__, (unsigned long)scanPaths.count);
    return [scanPaths copy];
}

- (NSArray *)getAppsByEnumDir {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (NSString *path in _appScanPathArray) {
        [self scanAppFromPath:path toResult:results depth:0];
    }
    
    return [results copy];
}

// 递归扫描. 判断 路径是不是app(是目录,并且是 package 类型)
- (BOOL)scanAppFromPath:(NSString *)path toResult:(NSMutableArray *)results depth:(NSInteger) depth{
    if (depth > 3) {
        return NO;
    }
    
    struct stat fileStat;
    if (lstat([path fileSystemRepresentation], &fileStat) != 0) {
        return NO;
    }

    //处理软链, 若果链接的目的地址是scanPaths中的子路径，则不进行扫描(避免重复扫描)
    if (fileStat.st_mode & S_IFLNK)
    {
        NSString *destination = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:path error:NULL];
        if (!destination)
            return NO;
        
        for (NSString *onePath in _appScanPathArray)
        {
            if ([destination hasPrefix:onePath])
            {
                return NO;
            }
            
        }
        
        path = destination;
    }
    //如果不是目录,不处理
    else if (!(fileStat.st_mode & S_IFDIR))
        return NO;
    
    //判定是否是package类型
    BOOL isPackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
    if (isPackage)
    {
        NSString *extension = [[path pathExtension] lowercaseString];
        if ([extension isEqualToString:@"app"] && [self fileVaild:path])
        {
            [results addObject:path];
            return YES;
        }
    } else {
        //添加子路径
        NSArray *childSubPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        for (NSString *childItem in childSubPaths)
        {
            NSString *childRelativePath = [path stringByAppendingPathComponent:childItem];
            [self scanAppFromPath:childRelativePath toResult:results depth:depth+1];
        }
    }
    return NO;
}


- (BOOL)fileVaild:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
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

@end
