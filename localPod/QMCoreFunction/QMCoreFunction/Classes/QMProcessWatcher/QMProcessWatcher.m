//
//  QMProcessWatcher.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMProcessWatcher.h"
#import <sys/event.h>

@interface QMProcessWatcher ()
{
    int queue;
    NSMutableDictionary *pidQuery;
}
@end

@implementation QMProcessWatcher

- (id)init
{
    self = [super init];
    if (self)
    {
        queue = kqueue();
        pidQuery = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (void)waitProcessExit:(pid_t)pid
{
    QMProcessWatcher *watcher = [[QMProcessWatcher alloc] init];
    [watcher watchProcess:pid];
    [watcher waitUntilExit];
}

+ (void)waitProcessesExit:(NSArray *)processes
{
    if (processes.count == 0)
        return;
    
    QMProcessWatcher *watcher = [[QMProcessWatcher alloc] init];
    [watcher watchProcesses:processes];
    [watcher waitUntilExit];
}

- (void)watchProcess:(pid_t)pid
{
    if ([pidQuery objectForKey:@(pid)])
        return;
    
    struct kevent inKev;
    EV_SET(&inKev, pid, EVFILT_PROC, EV_ADD | EV_ONESHOT, NOTE_EXIT, 0, NULL);
    kevent(queue, &inKev, 1, NULL, 0, NULL);
    
    [pidQuery setObject:@(YES) forKey:@(pid)];
}

- (void)watchProcesses:(NSArray *)processes
{
    if (processes.count == 0)
        return;
    
    for (NSNumber *pidObject in processes)
    {
        [self watchProcess:[pidObject intValue]];
    }
}

- (void)waitUntilExit
{    
    while (pidQuery.count > 0)
    {
        struct kevent reKev = {0};
        if (kevent(queue, NULL, 0, &reKev, 1, NULL) != -1)
        {
            if (reKev.filter == EVFILT_PROC && reKev.fflags == NOTE_EXIT)
            {
                pid_t pid = (pid_t)reKev.ident;
                [pidQuery removeObjectForKey:@(pid)];
            }
        }else
        {
            sleep(3);
        }
    }
}

@end
