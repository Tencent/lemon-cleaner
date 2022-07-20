//
//  LMAppSandboxHelper.m
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMAppSandboxHelper.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>

@interface LMAppSandboxHelper()

@property (nonatomic, strong) NSString *filePath;

@end

@implementation LMAppSandboxHelper

-(instancetype)init{
    self = [super init];
    if (self) {
        //判断有没有写相应的文件 没有则进行扫描
        if (![self isHaveSandboxFile]) {
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                [self initialSandboxFile];
//            });
        }
    }
    
    return self;
}

+(LMAppSandboxHelper *)shareInstance{
    static LMAppSandboxHelper *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[LMAppSandboxHelper alloc] init];
        [shareInstance getSandboxFilePath];
    });
    
    return shareInstance;
}

-(NSString *)getSandboxFilePath{
    if (self.filePath) {
        return self.filePath;
    }
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *bundleId = @"";
    bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *urlPaths = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appDirectory = [[urlPaths objectAtIndex:0] URLByAppendingPathComponent:bundleId isDirectory:YES];
    
    if (![fileManager fileExistsAtPath:[appDirectory path]]) {
        [fileManager createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
//    NSLog(@"app path is = %@", appDirectory);
    NSString *appSupportPath = [appDirectory path];
    NSString *filePath = [appSupportPath stringByAppendingPathComponent:@"dict2"];
    self.filePath = filePath;
    return filePath;
}

-(BOOL)isHaveSandboxFile{
    NSString *filePath = [self getSandboxFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        return YES;
    }
    
    return NO;
}

-(NSMutableDictionary *)getSandboxDic{
    NSString *filePath = [self getSandboxFilePath];
    NSMutableDictionary *sandboxDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    return sandboxDic;
}

//如果当前这个app是新增的 重新写入到文件中
-(void)rewriteToFileWithDic:(NSDictionary *)sanboxDic{
    @try {
        NSString *filePath = [self getSandboxFilePath];
//        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
//        [fileHandle seekToFileOffset:0];
//        [fileHandle truncateFileAtOffset:0];
//        [fileHandle closeFile];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        
        [sanboxDic writeToFile:filePath atomically:YES];
    } @catch (NSException *exception) {
        NSLog(@"exception = %@", exception);
    }
}

-(void)initialSandboxFile{
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask];
    
    NSError *error = nil;
    NSArray *properties = nil;
    
    NSArray *installArr = [[NSFileManager defaultManager]
                           contentsOfDirectoryAtURL:[urls objectAtIndex:0]
                           includingPropertiesForKeys:properties
                           options:(NSDirectoryEnumerationSkipsHiddenFiles)
                           error:&error];
    NSMutableDictionary *sandboxAppDic = [NSMutableDictionary new];
    for (NSURL *appUrl in installArr) {
        NSBundle *appBundle = [NSBundle bundleWithURL:appUrl];
        NSString *appIdentifier = [appBundle bundleIdentifier];
        if (appIdentifier == nil) {
            continue;
        }
        //开始获取是否是沙盒程序
        NSString *appPath = [appUrl path];
        BOOL isSandbox;
        if ([appIdentifier containsString:@"con.apple."]) {
            isSandbox = YES;
        }else{
            isSandbox = [self isAppIsSandboxByPath:appPath];
        }
        
        [sandboxAppDic setValue:[NSNumber numberWithBool:isSandbox] forKey:appIdentifier];
    }
    
    NSString *filePath = [self getSandboxFilePath];
    [sandboxAppDic writeToFile:filePath atomically:YES];
}

-(BOOL)isAppIsSandboxByPath:(NSString *)appPath{
    //        appPath = [appPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    @try{
        NSString *shellString = [NSString stringWithFormat:@"codesign -dv --entitlements :- '%@'", appPath];
        NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
        if ([retString isEqualToString:@""]) {
            return NO;
        }
        NSData* plistData = [retString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSPropertyListFormat format;
        NSDictionary* plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error];
        if (plist) {
            if ([[plist objectForKey:@"com.apple.security.app-sandbox"] boolValue]) {
                return YES;
            }else{
                return NO;
            }
        }
    }@catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }
    
    
    return NO;
}

//没有适配到的软件 在扫描中进行查看 防止刚上来获取卡主主线程
-(SandboxType)getAppSandboxTypeInScanWithBundleId:(NSString *)bundleId appPath:(NSString *)appPath{
    NSMutableDictionary *sanboxDic = [self getSandboxDic];
    if (sanboxDic == nil) {
        sanboxDic = [NSMutableDictionary new];
    }
    //新增的app
    BOOL isAppSandbox = [self isAppIsSandboxByPath:appPath];
    [sanboxDic setValue:[NSNumber numberWithBool:isAppSandbox] forKey:bundleId];
    [self rewriteToFileWithDic:sanboxDic];
    return isAppSandbox ? SandboxTypeYes : SandboxTypeNot;
}

-(SandboxType)getAppSandboxInfoWithBundleId:(NSString *)bundleId appPath:(NSString *)appPath{
    if (bundleId == nil) {
        return SandboxTypeNot;
    }
    NSMutableDictionary *sanboxDic = [self getSandboxDic];
    if (sanboxDic == nil) {
        sanboxDic = [NSMutableDictionary new];
    }
    //为了减轻执行shell的压力 先判断 bundleid拼接的路径是否存在
    NSFileManager *fileManger = [NSFileManager defaultManager];
    //是否在container中
    NSString *containerPath = [NSString stringWithFormat:@"%@/Library/Containers/%@", [NSString getUserHomePath], bundleId];
    if ([fileManger fileExistsAtPath:containerPath]) {
        [sanboxDic setValue:[NSNumber numberWithBool:YES] forKey:bundleId];
        [self rewriteToFileWithDic:sanboxDic];
        return SandboxTypeYes;
    }
    NSString *cachePath = [NSString stringWithFormat:@"%@/Library/Caches/%@", [NSString getUserHomePath], bundleId];
    if ([fileManger fileExistsAtPath:cachePath]) {
        [sanboxDic setValue:[NSNumber numberWithBool:NO] forKey:bundleId];
        [self rewriteToFileWithDic:sanboxDic];
        return SandboxTypeNot;
    }
    
    if ([[sanboxDic allKeys] containsObject:bundleId]) {
        return [[sanboxDic objectForKey:bundleId] boolValue] ? SandboxTypeYes : SandboxTypeNot;
    }else{
        return SandboxTypeNotDetermine;
    }
    return SandboxTypeNot;
}

@end
