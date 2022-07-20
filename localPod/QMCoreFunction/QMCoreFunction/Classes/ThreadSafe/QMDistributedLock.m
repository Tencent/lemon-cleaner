//
//  QMDistributedLock.m
//  Test
//
//  
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import "QMDistributedLock.h"
#import <sys/stat.h>
#import <sys/fcntl.h>

@interface QMDistributedLock ()
{
    NSString *filePath;
}
@end

@implementation QMDistributedLock

//用于同进程内的多线程间互斥
static NSMutableDictionary *g_threadLockInfo = nil;
+ (void)initialize
{
    if (self == [QMDistributedLock self])
    {
        g_threadLockInfo = [[NSMutableDictionary alloc] init];
    }
}

+ (QMDistributedLock *)lockWithPath:(NSString *)path
{
    return [[self alloc] initWithPath:path];
}

- (instancetype)init
{
    return nil;
}

- (instancetype)initWithPath:(NSString *)path
{
    @synchronized(self.class)
    {
        self = [super init];
        if (self)
        {
            filePath = [path copy];
            if (!filePath)
                return nil;
            
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            NSString *parentPath = [filePath stringByDeletingLastPathComponent];
            
            //父目录不存在
            if (![fileMgr fileExistsAtPath:parentPath])
                return nil;
            
            //父目录不可写
            if (![fileMgr isWritableFileAtPath:parentPath])
                return nil;
            
            //已经存在该名字的目录
            BOOL isDirectory = NO;
            if ([fileMgr fileExistsAtPath:filePath isDirectory:&isDirectory] && isDirectory)
            {
                if (![fileMgr removeItemAtPath:filePath error:NULL])
                    return nil;
            }
        }
        return self;
    }
}

- (BOOL)tryLock
{
    @synchronized(self.class)
    {
        if (g_threadLockInfo[filePath])
            return NO;
        
        int fileID = open([filePath fileSystemRepresentation], O_CREAT|O_RDWR,0666);
        chmod([filePath fileSystemRepresentation], 0666);
        if (fileID < 0)
        {
#ifdef DEBUG
            NSLog(@"[err] open fail: %s",strerror(errno));
#endif
            return NO;
        }

        struct flock lockinfo;
        lockinfo.l_type = F_WRLCK;
        lockinfo.l_whence = SEEK_SET;
        lockinfo.l_start = 0;
        lockinfo.l_len = 0;
        
        int re = fcntl(fileID, F_SETLK, &lockinfo);
        if (re != 0)
        {
            close(fileID);
            return NO;
        }
        
        NSTimeInterval interval = [NSDate timeIntervalSinceReferenceDate];
        lseek(fileID, 0, SEEK_SET);
        write(fileID, &interval, sizeof(interval));
        
        g_threadLockInfo[filePath] = @(fileID);
        
        return YES;
    }
}

- (void)unlock
{
    @synchronized(self.class)
    {
        NSNumber *fileObj = g_threadLockInfo[filePath];
        if (!fileObj) return;
        int fileID = [fileObj intValue];
        
        struct flock lockinfo;
        lockinfo.l_type = F_UNLCK;
        lockinfo.l_whence = SEEK_SET;
        lockinfo.l_start = 0;
        lockinfo.l_len = 0;
        
        fcntl(fileID, F_SETLK, &lockinfo);
        close(fileID);
        
        [g_threadLockInfo removeObjectForKey:filePath];
    }
}

- (void)breakLock
{
    @synchronized(self.class)
    {
        remove([filePath fileSystemRepresentation]);
        
        NSNumber *fileObj = g_threadLockInfo[filePath];
        if (!fileObj) return;
        int fileID = [fileObj intValue];
        
        close(fileID);
        [g_threadLockInfo removeObjectForKey:filePath];
    }
}

- (NSDate *)lockDate
{
    int fileID = open([filePath fileSystemRepresentation], O_RDONLY);
    if (fileID < 0)
        return nil;
    
    NSTimeInterval interval = 0;
    read(fileID, &interval, sizeof(interval));
    close(fileID);
    
    if (interval == 0)
        return nil;
    
    return [NSDate dateWithTimeIntervalSinceReferenceDate:interval];
}

@end
