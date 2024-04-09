//
//  InstallAppHelper.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "InstallAppHelper.h"

@implementation InstallAppHelper

//白名单  比如有的软件适配始终无垃圾的白名单过滤
static NSArray * getWhiteAppList(void) {
    static NSArray *whiteAppLists = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whiteAppLists = @[@"io.realm.realmbrowser", @"com.zennaware.cornerstone3.mas", @"com.sqlabs.sqlitemanager4"];
    });
    
    return whiteAppLists;
}

+(NSMutableDictionary *)getInstallBundleIds{
    
    NSMutableDictionary *installBundleIdDic = [[NSMutableDictionary alloc] init];
    
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask];
    
    if ([urls count] == 0) {
        return installBundleIdDic;
    }
    NSError *error = nil;
    NSArray *properties = nil;
    NSArray *installArr = nil;
    @try {
        /*
         在macOS13.0之后 '/Applications/Safari.app' 默认为隐藏文件。
         因此不能再使用NSDirectoryEnumerationSkipsHiddenFiles，修改为NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants,浅层遍历，不会遍历子目录，也不会遍历Package，更加符合需求
         
         后续判断（扩展名 != .app）会将隐藏的非应用的路径过滤掉
 
         NSString *path = [appUrl path];
         if (![[[path pathExtension] lowercaseString] isEqualToString:@"app"]){
             continue;
         }
         
         */
        
        installArr = [[NSFileManager defaultManager]
                               contentsOfDirectoryAtURL:[urls objectAtIndex:0]
                               includingPropertiesForKeys:properties
                               options:NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants
                               error:&error];
    } @catch (NSException *exception) {
        NSLog(@"getInstallBundleIds exception = %@", exception);
    }
    if ([installArr count] == 0) {
        return installBundleIdDic;
    }
    
    //Applications目录下可能有文件夹下面应用程序，首先进行一次过滤
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *spectilAppArr = [[NSMutableArray alloc] init];
    for (NSURL *appUrl in installArr) {
        NSBundle *appBundle = [NSBundle bundleWithURL:appUrl];
        NSString *appIdentifier = [appBundle bundleIdentifier];
        //appIdentifier 为空则return
        if (appIdentifier != nil) {
            continue;
        }
        
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:[appUrl path] isDirectory:&isDir];
        if (isDir) {
            NSDirectoryEnumerator * dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:[appUrl path]] includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsAliasFileKey] options:NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
            for (NSURL * pathURL in dirEnumerator)
            {
                if ([dirEnumerator level] == 1) {
                    [dirEnumerator skipDescendants];
                }
//                NSLog(@"pathurl = %@", [pathURL path]);
                NSString *path = [pathURL path];
                if (path && [[[path pathExtension] lowercaseString] isEqualToString:@"app"]){
                    [spectilAppArr addObject:pathURL];
                }
            }
        }
    }
    
    [spectilAppArr addObjectsFromArray:installArr];
    
    for (NSURL *appUrl in spectilAppArr) {
        NSBundle *appBundle = [NSBundle bundleWithURL:appUrl];
        NSString *appIdentifier = [appBundle bundleIdentifier];
        
        //appIdentifier 为空则return
        if (appIdentifier == nil) {
            appIdentifier = [appUrl lastPathComponent];
        }
        
        NSString *path = [appUrl path];
        if (![[[path pathExtension] lowercaseString] isEqualToString:@"app"]){
            continue;
        }
        
        //过滤自身
        if ([appIdentifier isEqualToString:@"com.tencent.Lemon"] || [appIdentifier isEqualToString:@"com.tencent.LemonLite"]) {
            continue;
        }
        
        //过滤微软的软件，防止用户重要文件丢失；edge浏览器除外
        if (![appIdentifier containsString:@"com.microsoft.edgemac"] && [appIdentifier containsString:@"com.microsoft"]&&![appIdentifier isEqualToString:@"com.microsoft.VSCode"]) {
            continue;
        }
        
        //过滤白名单软件 这些软件没有任何垃圾放在指定位置
        NSArray *whiteAppList = getWhiteAppList();
        if ([whiteAppList containsObject:appIdentifier]) {
            continue;
        }
        
        [installBundleIdDic setValue:[appUrl path] forKey:appIdentifier];
    }
    
    NSArray *inputUrls = [[NSFileManager defaultManager] URLsForDirectory:NSInputMethodsDirectory inDomains:NSLocalDomainMask];
    
    NSError *error1 = nil;
    NSArray *properties1 = nil;
    
    if ([inputUrls count] == 0) {
        return installBundleIdDic;
    }
    NSArray *inputInstallArr = nil;
    @try {
        inputInstallArr = [[NSFileManager defaultManager]
                                    contentsOfDirectoryAtURL:[inputUrls objectAtIndex:0]
                                    includingPropertiesForKeys:properties1
                                    options:(NSDirectoryEnumerationSkipsHiddenFiles)
                                    error:&error1];
    } @catch (NSException *exception) {
        NSLog(@"getInstallBundleIds exception = %@", exception);
    }
    
    for (NSURL *appUrl in inputInstallArr) {
        NSBundle *appBundle = [NSBundle bundleWithURL:appUrl];
        NSString *appIdentifier = [appBundle bundleIdentifier];
        
        //appIdentifier 为空则return
        if (appIdentifier == nil) {
            continue;
        }
        
        [installBundleIdDic setValue:[appUrl path] forKey:appIdentifier];
    }
    
    return installBundleIdDic;
}

@end
