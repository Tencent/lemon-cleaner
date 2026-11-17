//
//  LMAppleScriptStringEscape.h
//  LemonPhotoClean
//
//  AppleScript 字符串字面量转义（安全修复：S5-as5 sink B）。
//
//  背景：相似照片清理把磁盘枚举得到的文件名拼进 Photos AppleScript
//  （set listImages to {"name1","name2"}）。文件名是低信任输入
//  （任何同户进程可在 ~/Pictures 下伪造 photoslibrary 目录植入），
//  含双引号的文件名未转义内插可注入任意 AppleScript（含 do shell script），
//  注入代码以 Lemon 身份运行并继承其 TCC 授权面。
//

#ifndef LMAppleScriptStringEscape_h
#define LMAppleScriptStringEscape_h

#import <Foundation/Foundation.h>

/// AppleScript 字符串字面量转义：反斜杠 → 双反斜杠，双引号 → \"
/// （必须先转义反斜杠，顺序颠倒会导致已转义的引号被二次转义，留下注入面）。
/// @return 转义后的字符串；含换行（无法安全转义）或入参为 nil 时返回 nil，调用方须跳过该项
static inline NSString * _Nullable LMEscapeAppleScriptString(NSString * _Nullable string) {
    if (!string) return nil;
    if ([string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return nil;
    }
    NSString *escaped = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return escaped;
}

#endif /* LMAppleScriptStringEscape_h */
