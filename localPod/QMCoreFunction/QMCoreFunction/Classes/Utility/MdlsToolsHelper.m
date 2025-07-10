//
//  MdlsToolsHelper.m
//  LemonClener
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "MdlsToolsHelper.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>

@implementation MdlsToolsHelper

+(NSInteger)getAppSizeByPath:(NSString *)path andFileType:(NSString *)type{
    if ((path == nil) || [path isEqualToString:@""]) {
        return 0;
    }
    //目前trash中app无法使用这种方式获取到size
    if ([path containsString:@".Trash"]) {
        return 0;
    }
    //不以type结尾 直接返回0
    if (![[[path lastPathComponent] pathExtension] isEqualToString:type]) {
        return 0;
    }
    NSString *outString = [QMShellExcuteHelper excuteCmd:[NSString stringWithFormat:@"mdls \"%@\"", path]];
    if ((outString == nil) || [outString isEqualToString:@""]) {
        return 0;
    }
    NSArray *attrArray = [outString componentsSeparatedByString:@"\n"];
    NSString *phySize = nil;
    for (NSString *tempItemAttr in attrArray) {
        if ([tempItemAttr containsString:@"kMDItemPhysicalSize"]) {
            phySize = tempItemAttr;
        }
    }
    if (phySize == nil) {
        return 0;
    }
    
    NSArray *phySizeArr = [phySize componentsSeparatedByString:@"="];
    if ([phySizeArr count] <= 1) {
        return 0;
    }
    
    NSString *sizeString = [phySizeArr objectAtIndex:1];
    return [sizeString integerValue];
}

+ (void)redirectLogToFileAtPath:(NSString *)path forDays:(NSInteger)persistDays maxSize:(unsigned long long)maxSize {
    
    if (!path || persistDays <= 0 || maxSize <= 0) return;
    
    NSString *logPath = path;
    id fileHandle = nil;
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:logPath]) {
        [fileMgr createFileAtPath:logPath contents:[NSData data] attributes:nil];
    } else {
        NSDictionary *fileAttributes = [fileMgr attributesOfItemAtPath:logPath error:nil];
        if (fileAttributes) {
            unsigned long long fileSize = [fileAttributes fileSize];
            NSDate *date = [fileAttributes fileCreationDate];
            NSTimeInterval createTimeInterval = [date timeIntervalSince1970];
            NSTimeInterval todayTimeInterval = [[NSDate date] timeIntervalSince1970];

            // 日志文件大小限制
            BOOL isFileSizeExceeded = fileSize > (maxSize * 1024 * 1024);
            
            // 日志创建时间限制
            // createTimeInterval is 0，属于异常，重新创建文件也合理
            BOOL isExpired = (todayTimeInterval - createTimeInterval) > (persistDays * 24 * 3600);

            if (isFileSizeExceeded || isExpired) {
                [fileMgr removeItemAtPath:logPath error:nil];
                [fileMgr createFileAtPath:logPath contents:[NSData data] attributes:nil];
            }
        }
    }
    
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    [fileHandle seekToEndOfFile];
    if (fileHandle != nil)
    {
        dup2([fileHandle fileDescriptor], STDERR_FILENO);
    }
    [fileHandle closeFile];
}

@end
