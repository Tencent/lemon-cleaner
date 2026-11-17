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

/// 调用方法在串行队列上的情况，直接调用这个
- (void)removeFileToTrashInSerialQueue:(NSString *)filePath;

/// AppleScript 字符串字面量转义（安全修复：S5-as5 sink A）。
/// 文件名是磁盘枚举得到的低信任输入，内插进脚本源码前必须转义：
/// 反斜杠 → 双反斜杠，双引号 → \"（先转义反斜杠，防二次转义 bypass）。
/// @return 转义后的字符串；含换行（无法安全转义）或入参为 nil 时返回 nil，调用方须回退处理
+ (nullable NSString *)escapedAppleScriptLiteral:(nullable NSString *)string;

@end

NS_ASSUME_NONNULL_END
