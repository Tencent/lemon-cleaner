//
//  QMDownloadManager.m
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMDownloadManager.h"
#import "QMDownloadTask.h"
#import "QMSafeMutableArray.h"
#import "QMDownloadItemPrivate.h"

NSString *QMDownloadListChangedNotification = @"QMDownloadListChangedNotification";

@interface QMDownloadManager ()<QMDownloadTaskDelegate>
{
    NSOperationQueue *taskQueue;
    QMSafeMutableArray *items;
}
@end

@implementation QMDownloadManager
@synthesize downloadDirectory;
@synthesize concurrentCount;

+ (id)sharedManager
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
        /*
        //默认线程数为(CPU的核数-1)(至少两个线程)
        NSUInteger processorCount = [[NSProcessInfo processInfo] processorCount];
        concurrentCount = MAX(processorCount-1, 2);
         */
        concurrentCount = 3;
        taskQueue = [[NSOperationQueue alloc] init];
        [taskQueue setMaxConcurrentOperationCount:concurrentCount];
        items = [[QMSafeMutableArray alloc] init];
        downloadDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads/QQMgrDL"];
    }
    return self;
}

- (void)postListChangedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:QMDownloadListChangedNotification
                                                        object:self
                                                      userInfo:nil];
}

#pragma mark -

- (NSUInteger)countOfConcurrentCount
{
    return concurrentCount;
}

- (void)setConcurrentCount:(NSInteger)value
{
    if (concurrentCount != value)
    {
        concurrentCount = value;
        [taskQueue setMaxConcurrentOperationCount:concurrentCount];
    }
}

- (NSArray *)downloadItems
{
    return [NSArray arrayWithArray:items];
}

- (QMDownloadItem *)itemWithContext:(id)context
{
    if (!context)
        return nil;
    
    QMDownloadItem *result = nil;
    
    [items lock];
    for (QMDownloadItem *oneItem in items)
    {
        if ([oneItem.context isEqualTo:context])
        {
            result = oneItem;
            break;
        }
    }
    [items unlock];
    
    return result;
}

- (void)startDownload:(QMDownloadItem *)item
{
    if (!item)
        return;
    
    if (![items containsObject:item])
        [items addObject:item];
    
    NSArray *operations = taskQueue.operations;
    for (QMDownloadTask *task in operations)
    {
        if (task.item == item && !task.isCancelled)
            return;
    }
    
    item.status = QMDownloadStatusWait;
    [item postNotification];
    
    QMDownloadTask *downTask = [[QMDownloadTask alloc] initWithItem:item];
    downTask.delegate = self;
    downTask.downloadDirectory = downloadDirectory;
    [taskQueue addOperation:downTask];
    
    [self postListChangedNotification];
}

- (void)puseDownload:(QMDownloadItem *)item
{
    if (!item)
        return;
    
    NSArray *operations = taskQueue.operations;
    for (QMDownloadTask *task in operations)
    {
        if (task.item == item)
        {
            [task cancel];
        }
    }
    
    item.status = QMDownloadStatusPaused;
    [item postNotification];
}

- (void)stopDownload:(QMDownloadItem *)item
{
    if (!item)
        return;
    
    [items removeObject:item];
    
    NSArray *operations = taskQueue.operations;
    for (QMDownloadTask *task in operations)
    {
        if (task.item == item)
        {
            [task cancel];
        }
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:item.filePath error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:item.downloadInfoPath error:NULL];
    item.status = QMDownloadStatusCancel;
    [item postNotification];
    
    [self postListChangedNotification];
}

#pragma mark -

- (void)downloadUpdate:(QMDownloadTask *)task
{
    [task.item postNotification];
    if (task.item.status == QMDownloadStatusFinish)
    {
        [items removeObject:task.item];
    }
}

@end
