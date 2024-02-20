//
//  LMAppleScriptTool.h
//  LemonFileManager
//
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMAppleScriptTool : NSObject

/// 删除文件到垃圾桶
- (void)removeFileToTrash:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
