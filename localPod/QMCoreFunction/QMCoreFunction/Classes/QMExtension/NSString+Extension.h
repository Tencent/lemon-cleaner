//
//  NSString+FileSize.h
//  McCleaner
//
//
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_INLINE NSString* QMSafeSTR(id string)
{
    if (!string || ![string isKindOfClass:[NSString class]])
        return @"";
    return string;
}

// 二进制倍数；通常情况Mac上硬盘是以1000计算
extern NSInteger binary_multiple(void);

@interface NSString(FileSize)

+ (NSString *)stringFromDiskSize:(uint64_t)theSize;
+ (NSString *)stringFromDiskSize:(uint64_t)theSize delimiter:(NSString *)delimiter;

+ (NSString *)sizeStringFromSize:(uint64_t)theSize diskMode:(BOOL)diskMode;
+ (NSString *)unitStringFromSize:(uint64_t)theSize diskMode:(BOOL)diskMode;
+ (NSString *)stringFromSize:(uint64_t)theSize delimiter:(NSString *)delimiter diskMode:(BOOL)diskMode;
+ (NSString *)stringFromSize:(uint64_t)theSize delimiter:(NSString *)delimiter diskMode:(BOOL)diskMode length:(uint8_t)length;

+ (NSString *)stringFromMBSize:(uint64_t)theSize delimiter:(NSString *)delimiter diskMode:(BOOL)diskMode;

@end

@interface NSString(Speed)

+ (NSString *)stringFromNetSpeed:(CGFloat)value;
+ (NSString *)stringFromNetSpeedWithoutSpacing:(CGFloat)value;
@end

@interface NSString(LMPath)

- (BOOL)isParentPath:(NSString *)childPath;
+(NSString *)getUserHomePath;

@end

@interface NSString(Truncates)

typedef enum
{
    QMTruncatingHead,
    QMTruncatingTail,
    QMTruncatingMiddle
}QMTruncatingMode;

- (NSString *)truncatesString:(QMTruncatingMode)mode length:(NSInteger)length;

@end

@interface NSString(Version)

- (NSString *)versionString;
- (NSString *)buildVersionString;
- (BOOL)compareVersion:(NSString*)otherVersion;

@end

@interface NSString (FindBundle)
- (NSString *)findBundlePath;
@end

@interface NSString (Coding)

- (NSString *)replaceUnicode;

@end
@interface NSString (MD5)
- (NSString *)md5String;
@end



