//
//  LMAppleScriptTool.m
//  LemonFileManager
//
//

#import "LMAppleScriptTool.h"

@interface LMAppleScriptTool ()

@property (nonatomic, strong) dispatch_queue_t appleScriptSerialQueue;

@end

@implementation LMAppleScriptTool

- (instancetype)init {
    self = [super init];
    if (self) {
        self.appleScriptSerialQueue = dispatch_queue_create("largeold.applescript.remove.file", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

/// 删除文件到垃圾桶
- (void)removeFileToTrash:(NSString *)filePath {
    dispatch_async(self.appleScriptSerialQueue, ^{
        [self _removeFileToTrash:filePath];
    });
}

/// 调用方法在串行队列上的情况，直接调用这个
- (void)removeFileToTrashInSerialQueue:(NSString *)filePath {
    [self _removeFileToTrash:filePath];
}

- (void)_removeFileToTrash:(NSString *)filePath {
    if (!filePath || ![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
        NSLog(@"remove file : %@", filePath);
        return;
    }
#ifndef APPSTORE_VERSION
    // 发现替换成API的方式，会有下面这个问题
    // 1、当用户重复删除某一个文件->放回原处->再次删除这个文件，废纸篓中右键不会在出现“放回原处”，当删除一个不同的文件，所有文件的“放回原处”又会重新出现
    // 2、删除某一个文件->点击“放回原处”->Lemon重启->还是删除这个文件，右键有“放回原处”
    // 说明系统废纸篓可能记录了某个文件的删除记录，并且和进程绑定。
    // 只能回滚到 applescript 的方式，同时设置开始删除前静音，结束后恢复声音，避免批量删除时系统提示音产生的噪音
    // 后续可能的解决办法：使用xpc服务的方式，因xpc是按需启动，在xpc服务中通过api的方式来删除文件，所以理论上可行（批量删除需要验证）。改动太大先mark
    NSString *appleScriptSource = [NSString stringWithFormat:
                                   @"set volume output muted true\n"
                                   @"tell application \"Finder\"\n"
                                   @"set theFile to POSIX file \"%@\"\n"
                                   @"delete theFile\n"
                                   @"end tell\n"
                                   @"set volume output muted false", filePath];
    
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:appleScriptSource];
    NSDictionary *errorDict;
    NSAppleEventDescriptor *returnDescriptor = [appleScript executeAndReturnError:&errorDict];
    
    if (returnDescriptor == nil) {
        if (errorDict != nil) {
            NSLog(@"QMLargeOldManager: moveFileToTrashError: %@", [errorDict objectForKey:NSAppleScriptErrorMessage]);
        } else {
            
            NSLog(@"QMLargeOldManager: moveFileToTrashError: unknownError");
        }
    }
#else
    NSArray *urls = @[[NSURL fileURLWithPath:filePath]];
    [[NSWorkspace sharedWorkspace] recycleURLs:urls
                             completionHandler:^void(NSDictionary *newURLs, NSError *recycleError) {
        NSLog(@"exec recycleURLs error : %@", recycleError);
    }];
#endif
    
}

@end
