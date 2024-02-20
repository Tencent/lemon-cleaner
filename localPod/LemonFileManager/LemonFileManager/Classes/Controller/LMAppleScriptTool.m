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
        NSString *appleScriptSource = [NSString stringWithFormat:
                                       @"tell application \"Finder\"\n"
                                       @"set theFile to POSIX file \"%@\"\n"
                                       @"delete theFile\n"
                                       @"end tell", filePath];
        
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
    });
}

@end
