//
//  McLogUtil.m
//  TestFunction
//
//  Created by developer on 11-1-11.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "McLogUtil.h"

const char *g_logLevelName[] = 
{
    "[ERROR]",
    "[WARN]",
    "[INFO]"
};

char g_szlogFilePath[300] = "/tmp/mclogtest.log";

// wrapper of log
void McLog(uint logLevel, NSString *format, ...)
{
#ifndef DEBUG
    return;
#endif
    
    // level check
    if (logLevel >= MCLOG_LEVEL)
        return;
    
    va_list ap;
    va_start(ap, format);
    NSString *origLogStr = [[NSString alloc] initWithFormat:format arguments:ap];
    NSString *logStr = [NSString stringWithFormat:@"%s %@", g_logLevelName[logLevel], origLogStr];
    
#ifdef MCLOG_USENSLOG
    
    // just use NSLog
    NSLog(@"%@", logStr);
    
#else
    
    // log to file
    NSDate *curDate = [NSDate date];
    NSProcessInfo *myProcess = [NSProcessInfo processInfo];
    NSString *logFileStr = [NSString stringWithFormat:@"%@ %@[%d] %@\n",
                            curDate, [myProcess processName], [myProcess processIdentifier], logStr];
    
    // output to log file
    NSString *logFilePath = [NSString stringWithUTF8String:g_szlogFilePath];
    // create file if need
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:logFilePath])
    {
        if (![fileMgr createFileAtPath:logFilePath contents:nil attributes:nil])
        {
            NSLog(@"error create log file");
            return;
        }
    }
    // append data to file
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    if (fileHandle == nil)
        return;
    [fileHandle seekToEndOfFile];
    NSData *fileData = [NSData dataWithBytes:[logFileStr cString] length:[logFileStr length]];
    [fileHandle writeData:fileData];
    [fileHandle closeFile];
    
#endif // MCLOG_USENS
    
}
