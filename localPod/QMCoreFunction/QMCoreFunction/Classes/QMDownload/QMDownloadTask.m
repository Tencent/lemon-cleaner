//
//  QMDownloadTask.m
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMDownloadTask.h"
#import "QMCryptUtility.h"
#import "NSFileManager+Extension.h"
#import "QMHeaderResponse.h"
#import "QMDownloadItemPrivate.h"
#import <sys/stat.h>

#define kQMDOWNTASK_TRYMAX 5
#define kQMDOWNTASK_UPDATESEC 1.0
#define kQMDOWNTASK_CACHEMAX (1024*1024*5)
#define kQMDOWNTASK_INFO_NAME @"NAME"
#define kQMDOWNTASK_INFO_SIZE @"SIZE"
#define kQMDOWNTASK_INFO_SPEND @"SPEND"

@interface QMDownloadTask ()
{
    int tryCount;
    uint64_t offset;
    CFRunLoopRef runloop;
    NSTimeInterval interval;
    NSFileHandle *fileHandle;
    NSMutableData *cacheData;
    NSURLConnection *downloader;
    NSFileManager *fileManager;
    
    NSString *downloadInfoPath;
    NSMutableDictionary *downloadInfo;
    
    NSString *downloadPath;
    NSString *resultPath;
}
@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL isFinished;
@end

@implementation QMDownloadTask
@synthesize isExecuting,isCancelled,isFinished;
@synthesize item,delegate,downloadDirectory;

- (id)initWithItem:(QMDownloadItem *)aItem
{
    self = [super init];
    if (self)
    {
        item = aItem;
    }
    return self;
}

- (void)main
{
    if (self.isCancelled || self.isFinished)
        return;
    if (!item.url)
    {
        [self downloadFaild:nil];
        return;
    }
    
    self.isExecuting = YES;
    item.status = QMDownloadStatusDoing;
    [delegate downloadUpdate:self];
    
    NSError *error = nil;
    fileManager = [NSFileManager defaultManager];
    
    //预先请求头
    NSHTTPURLResponse *response = [QMHeaderResponse headerResponse:item.url error:&error];
    if (!response || error)
    {
        [self downloadFaild:error];
        return;
    }
    
    //设置文件名
    NSString *suggestedFilename = [response suggestedFilename];
    if (suggestedFilename)
        item.fileName = [response suggestedFilename];
    else
        item.fileName = [[item.url absoluteString] lastPathComponent];
    item.fileSize = [response expectedContentLength];
    
    //判定下载的目录是否存在(如果不存在则创建该目录,创建失败则使用临时目录)
    if (![fileManager fileExistsAtPath:downloadDirectory])
    {
        BOOL createStatus = [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        if (!createStatus)
        {
            downloadDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"QQMgrDL"];
            [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    
    //根据缓存信息判定是否可以继续下载
    BOOL continueDown = NO;
    downloadInfoPath = [NSString stringWithFormat:@"%@/.%@.downloadInfo",downloadDirectory,item.fileName];
    downloadInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:downloadInfoPath];
    if (downloadInfo &&
        [item.fileName isEqualTo:[downloadInfo objectForKey:kQMDOWNTASK_INFO_NAME]] &&
        item.fileSize == [[downloadInfo objectForKey:kQMDOWNTASK_INFO_SIZE] longLongValue])
    {
        continueDown = YES;
        item.totalSpendTime = [[downloadInfo objectForKey:kQMDOWNTASK_INFO_SPEND] doubleValue];
    }else
    {
        downloadInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        item.fileName,kQMDOWNTASK_INFO_NAME,
                        @(item.fileSize),kQMDOWNTASK_INFO_SIZE, nil];
    }
    item.downloadInfoPath = downloadInfoPath;
    
    //设置下载结束的地址,并判定已经存在的文件是否与下载的相同(根据文件大小)
    resultPath = [NSString stringWithFormat:@"%@/%@",downloadDirectory,item.fileName];
    if ([fileManager fileExistsAtPath:resultPath])
    {
        if (item.fileSize == [fileManager fileSizeAtPath:resultPath])
        {
            downloadPath = resultPath;
            item.filePath = downloadPath;
            [self downloadFinished];
            return;
        }
    }
    
    //设置下载路径,并根据是否支持继传创建下载任务
    downloadPath = [NSString stringWithFormat:@"%@/.%@.download",downloadDirectory,item.fileName];
    BOOL fileExists = [fileManager fileExistsAtPath:downloadPath];
    if (fileExists && !continueDown)
    {
        fileExists = NO;
        if (![fileManager removeItemAtPath:downloadPath error:&error])
        {
            [self downloadFaild:error];
            return;
        }
    }
    if (!fileExists && ![fileManager createFileAtPath:downloadPath contents:nil attributes:nil])
    {
        [self downloadFaild:nil];
        return;
    }
    item.filePath = downloadPath;
    
    //创建文件Handle
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:item.filePath];
    offset = [fileHandle seekToEndOfFile];
    if (offset == item.fileSize)
    {
        [self downloadFinished];
        return;
    }
    
    //开始下载
    [self createConnection];
    
    //再次判定状态
    if (self.isCancelled || self.isFinished)
    {
        [self cleanUp];
        return;
    }
    
    //开启RunLoop,并等待结束
    runloop = CFRunLoopGetCurrent();
    CFRunLoopRun();
    
    self.isExecuting = NO;
    self.isFinished = YES;
}

//创建下载链接
- (void)createConnection
{
    tryCount++;
    [downloader cancel];
    downloader = nil;
    
    //创建下载器(通过Range实现继续下载)
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:item.url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:30];
    [request addValue:[NSString stringWithFormat:@"bytes=%llu-",offset] forHTTPHeaderField:@"Range"];
    downloader = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [downloader scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//清理对象,结束runloop
- (void)cleanUp
{
    [downloader cancel];
    downloader = nil;
    [fileHandle closeFile];
    fileHandle = nil;
    if (runloop)
    {
        CFRunLoopStop(runloop);
        runloop = NULL;
    }
}

//将文件缓存写入文件
- (void)refreshFileCache
{
    if (cacheData.length == 0)
        return;
    
    offset += cacheData.length;
    
    //计算速度,进度
    NSTimeInterval currentInterval = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval spendTime = currentInterval - interval;
    if (spendTime > 0)
        item.speed = cacheData.length/spendTime;
    interval = currentInterval;
    item.latestSpendTime += spendTime;
    
    //计算平均速度,保存耗费总时间
    NSTimeInterval totalSpendTime = [[downloadInfo objectForKey:kQMDOWNTASK_INFO_SPEND] doubleValue];
    totalSpendTime += spendTime;
    item.totalSpendTime = totalSpendTime;
    if (totalSpendTime > 0)
        item.averageSpeed = offset/totalSpendTime;
    [downloadInfo setObject:@(totalSpendTime) forKey:kQMDOWNTASK_INFO_SPEND];
    [downloadInfo writeToFile:downloadInfoPath atomically:YES];
    
    //有可能服务器没有返回size
    if (item.fileSize > 0)
    {
        double progress = offset*1.0/item.fileSize;
        item.progress = MIN(progress, 1.0);
    }
    
    [fileHandle writeData:cacheData];
    [cacheData replaceBytesInRange:NSMakeRange(0, cacheData.length)
                         withBytes:NULL
                            length:0];
    
    
    [delegate downloadUpdate:self];
}

- (void)downloadFaild:(NSError *)error
{
    [self cleanUp];
    item.status = QMDownloadStatusFaild;
    [delegate downloadUpdate:self];
    
    self.isFinished = YES;
}

- (void)downloadFinished
{
    [self cleanUp];
    
    //删除下载的相关信息
    [fileManager removeItemAtPath:downloadInfoPath error:NULL];
    
    //比对Hash值(支持MD5和SHA1校验),比对不成功删除安装包
    if ( (item.hash_md5.length > 0 && [item.hash_md5 compare:[QMCryptUtility hashFile:item.filePath with:QMHashKindMd5] options:NSCaseInsensitiveSearch])!=NSOrderedSame ||
        (item.hash_sha1.length > 0 && [item.hash_sha1 compare:[QMCryptUtility hashFile:item.filePath with:QMHashKindSha1] options:NSCaseInsensitiveSearch]!=NSOrderedSame) )
        
    {
        item.progress = 0.0;
        [fileManager removeItemAtPath:item.filePath error:NULL];
        [self downloadFaild:nil];
        return;
    }
    
    //如果已经存在,先删除再移动,并处理移动失败的情况
    if (![resultPath isEqualTo:downloadPath])
    {
        if ([fileManager fileExistsAtPath:resultPath])
        {
            [fileManager removeItemAtPath:resultPath error:NULL];
        }
        if (![fileManager moveItemAtPath:item.filePath toPath:resultPath error:NULL])
        {
            [self downloadFaild:nil];
            return;
        }
    }
    
    item.filePath = resultPath;
    item.progress = 1.0;
    item.status = QMDownloadStatusFinish;
    [delegate downloadUpdate:self];
    
    self.isFinished = YES;
}

- (void)cancel
{
    //判定是否在同一线程,不在同一线程,将任务提交到当前线程中
    if (runloop && !CFEqual(runloop, CFRunLoopGetCurrent()))
    {
        CFRunLoopTimerContext timerContext;
        bzero(&timerContext, sizeof(timerContext));
        timerContext.info = (__bridge void*)self;
        
        CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent(), 0, 0, 0, &cancelCallBack, &timerContext);
        CFRunLoopAddTimer(runloop, timer, kCFRunLoopCommonModes);
        CFRelease(timer);
        return;
    }
    [self safeCancel];
}

static void cancelCallBack(CFRunLoopTimerRef timer __unused, void *info)
{
    QMDownloadTask *task = (__bridge QMDownloadTask*)info;
    [task safeCancel];
}

- (void)safeCancel
{
    [self cleanUp];
    
    self.isFinished = YES;
    self.isCancelled = YES;
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (statusCode >= 400)
    {
        //416所请求的范围无法满足,尝试从0开始下载
        if (statusCode == 416)
        {
            offset = 0;
            [fileHandle truncateFileAtOffset:0];
        }
        
        //重试机制
        if (tryCount < kQMDOWNTASK_TRYMAX)
        {
            [self createConnection];
        }else
        {
            NSString *localizedForStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
            NSDictionary *errorInfo = localizedForStatusCode ? @{NSLocalizedDescriptionKey: localizedForStatusCode} : nil;
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:statusCode userInfo:errorInfo];
            [self downloadFaild:error];
        }
    }else
    {
        interval = [NSDate timeIntervalSinceReferenceDate];
        cacheData = [[NSMutableData alloc] init];
        item.latestSpendTime = 0.0;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)aData
{
    [cacheData appendData:aData];
    
    //当内存中的数据超过上限或超过更新间隔(计算速度,写磁盘)
    NSTimeInterval currentInterval = [NSDate timeIntervalSinceReferenceDate];
    if (currentInterval-interval > kQMDOWNTASK_UPDATESEC || cacheData.length > kQMDOWNTASK_CACHEMAX)
    {
        [self refreshFileCache];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self refreshFileCache];
    [self downloadFaild:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self refreshFileCache];
    [self downloadFinished];
}

@end
