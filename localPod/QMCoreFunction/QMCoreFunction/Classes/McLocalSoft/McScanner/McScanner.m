//
//  McScanner.m
//  McSoftware
//
//  Created by developer on 10/17/12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McScanner.h"
#import <sys/stat.h>

#define kSearchPathsLevel 3

@interface McScanner ()
{
    BOOL isScan;
    BOOL isDispatch;
    NSLock *lock;
    NSTimeInterval updateDate;
    NSMutableArray *updateResults;
    NSMutableArray *scannerResults;
    
    dispatch_queue_t outsideQueue;
    void(^scanHandler)(NSArray *,BOOL);
}
@end

@implementation McScanner

+ (id)scanner
{
    return [[self alloc] init];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        lock = [[NSLock alloc] init];
    }
    return self;
}

- (BOOL)scanning
{
    return isScan||isDispatch;
}

- (void)stopScan
{
    isScan = NO;
}

- (NSArray *)results
{
    [lock lock];
    NSArray *results = [[NSArray alloc] initWithArray:scannerResults];
    [lock unlock];
    return results;
}

#pragma mark -
#pragma mark 子类重写

- (NSArray *)scanPaths
{
    return nil;
}

- (McLocalType)scanType
{
    return 0;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        return NO;
    }
    return YES;
}

- (BOOL)bundleVaild:(NSBundle *)bundle
{
    //不处理苹果软件
    if ([bundle.bundleIdentifier hasPrefix:@"com.apple"])
        return NO;
    
    //不处理自身软件
    if ([bundle.bundleIdentifier hasPrefix:@"com.tencent.Lemon"])
        return NO;
    
    return YES;
}

#pragma mark -

- (void)updateResult:(McLocalSoft *)localSoft
{
    if (!localSoft)
        return;
    
    //将新记录添加到结果中
    [lock lock];
    [scannerResults addObject:localSoft];
    [lock unlock];
    
    //将新记录添加到增量结果中
    [updateResults addObject:localSoft];
    
    //让刷新进度不低于1秒
    NSTimeInterval currentDate = [NSDate timeIntervalSinceReferenceDate];
    if (currentDate - updateDate < 1)
        return;
    
    //发送列表更新的通知
    updateDate = currentDate;
    NSArray *updateArray = [NSArray arrayWithArray:updateResults];
    dispatch_async(outsideQueue, ^{
        scanHandler(updateArray,NO);
    });
    
    [updateResults removeAllObjects];
}

- (void)enumScanner
{
    NSArray *scanPaths = [self scanPaths];
    for (NSString *scanFilePath in scanPaths)
    {
        NSMutableArray *searchPaths = [[NSMutableArray alloc] initWithObjects:@"",nil];
        while ([searchPaths count] > 0)
        {
            @autoreleasepool
            {
                //外部停止扫描
                if (!isScan)
                    return;
                
                NSString *fileItem = [searchPaths objectAtIndex:0];
                [searchPaths removeObjectAtIndex:0];
                NSString *fullPath = [scanFilePath stringByAppendingPathComponent:fileItem];
                
                struct stat fileStat;
                if (lstat([fullPath fileSystemRepresentation], &fileStat) == 0)
                {
                    //如果是软链
                    if (fileStat.st_mode & S_IFLNK)
                    {
                        BOOL contains = NO;
                        NSString *destination = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:fullPath error:NULL];
                        if (!destination)
                            continue;
                        
                        for (NSString *onePath in scanPaths)
                        {
                            if ([destination hasPrefix:onePath])
                            {
                                contains = YES;
                                break;
                            }
                                
                        }
                        if (contains)
                            continue;
                        
                        fullPath = destination;
                    }
                    //如果不是目录,不处理
                    else if (!(fileStat.st_mode & S_IFDIR))
                        continue;
                    
                    //判定是否是package类型
                    BOOL isPackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:fullPath];
                    if (isPackage)
                    {
                        if (![self fileVaild:fullPath])
                            continue;
                        
                        NSBundle *bundle = [NSBundle bundleWithPath:fullPath];
                        if (!bundle)
                            continue;
                        
                        if (![self bundleVaild:bundle])
                            continue;
                        
                        McLocalSoft *localSoft = [McLocalSoft softWithBundle:bundle];
                        localSoft.type = [self scanType];
                        [self updateResult:localSoft];
                        continue;
                    }
                    
                    //判定路径层数
                    if ([[fileItem pathComponents] count] >= kSearchPathsLevel)
                        continue;
                    
                    //添加子路径
                    NSArray *childSubPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:nil];
                    for (NSString *childItem in childSubPaths)
                    {
                        NSString *childRelativePath = [fileItem stringByAppendingPathComponent:childItem];
                        [searchPaths insertObject:childRelativePath atIndex:0];
                    }
                }
            }
        }
    }
}

- (void)scanWithHandler:(void(^)(NSArray *updates,BOOL finished))handler
{
    if ([self scanning])
        return;
    
    //标识扫描开启(外部停止时置为NO)
    isScan = YES;
    //标识线程开启(只有当任务彻底退出才置为NO)
    isDispatch = YES;
    
    outsideQueue = dispatch_get_current_queue();
    scanHandler = [handler copy];
    updateDate = [NSDate timeIntervalSinceReferenceDate];
    updateResults = [[NSMutableArray alloc] init];
    scannerResults = [[NSMutableArray alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //开始检索
        [self enumScanner];
        
        //处理剩下的增量数量
        NSArray *updateArray = ([updateResults count]>0)?updateResults:nil;
        updateResults = nil;
        
        //通知外部线程,并在主线程清理状态
        dispatch_async(outsideQueue, ^{
            scanHandler(updateArray,YES);
            scanHandler = NULL;
            
            outsideQueue = NULL;
            isDispatch = NO;
            isScan = NO;
        });
    });
}

@end
