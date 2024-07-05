//
//  NSString+FileSize.m
//  McCleaner
//
//  
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSString+Extension.h"
#import "NSData+Extension.h"

// 硬盘模式
static const BOOL __diskMode__ = YES;

// 二进制倍数
NS_INLINE NSInteger __binary_multiple__(BOOL diskMode);

inline NSInteger binary_multiple(void) {
    return __binary_multiple__(__diskMode__);
}

NS_INLINE NSInteger __binary_multiple__(BOOL diskMode) {
    return diskMode ? 1000 : 1024;
}

@implementation NSString(FileSize)

+ (NSString *)stringFromDiskSize:(uint64_t)theSize
{
    return [self stringFromDiskSize:theSize delimiter:@" "];
}

+ (NSString *)stringFromDiskSize:(uint64_t)theSize delimiter:(NSString *)delimiter
{
    return [self stringFromSize:theSize delimiter:delimiter diskMode:__diskMode__];
}

+ (NSString *)sizeStringFromSize:(uint64_t)theSize diskMode:(BOOL)diskMode{
    return [NSString stringFromSize:theSize delimiter:@" " diskMode:diskMode needUnit:NO];
}
+ (NSString *)unitStringFromSize:(uint64_t)theSize diskMode:(BOOL)diskMode{
    const NSString* sizeUnit[] = {@"B",@"KB",@"MB",@"GB",@"TB",@"PB"};
    
    NSInteger idx = 0;
    double floatSize = theSize;
    while (floatSize>1000 && idx < (sizeof(sizeUnit)/sizeof(sizeUnit[0])-1))
    {
        idx++;
        floatSize /= __binary_multiple__(diskMode);
    }
    
    return [NSString stringWithFormat:@"%@",sizeUnit[idx]];
}

/*
 根据指定参数返回格式化的字符串
 theSize:文件的byte数
 delimiter:返回字串数字与单位之间的分隔符
 diskMode:硬盘表示方式,YES时换算除1000,NO时换算除1024
 */
+ (NSString *)stringFromSize:(uint64_t)theSize delimiter:(NSString *)delimiter diskMode:(BOOL)diskMode
{
//    const NSString* sizeUnit[] = {@"B",@"KB",@"MB",@"GB",@"TB",@"PB"};
//
//    NSInteger idx = 0;
//    double floatSize = theSize;
//    while (floatSize>1000 && idx < (sizeof(sizeUnit)/sizeof(sizeUnit[0])-1))
//    {
//        idx++;
//        if (diskMode)
//            floatSize /= 1000;
//        else
//            floatSize /= 1024;
//    }
//
//    if (idx == 0)
//    {
//        return [NSString stringWithFormat:@"%.0f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
//    }else
//    {
//        //整数为0保留2位小数
//        if (floatSize < 0)
//            return [NSString stringWithFormat:@"%.2f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
//
//        //保留一位小数(注意99.95的情况)
//        if (round(floatSize*10) < 1000)
//            return [NSString stringWithFormat:@"%.1f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
//
//        //整数位大于等于3,不保留小数
//        return [NSString stringWithFormat:@"%.0f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
//    }
    
    //修复整除问题（floatSize>=1000）及小数显示问题（整除不显示小数）。
    return [NSString stringFromSize:theSize delimiter:delimiter diskMode:diskMode needUnit:YES];
}

/*
 根据指定参数返回格式化的字符串
 theSize:文件的byte数
 delimiter:返回字串数字与单位之间的分隔符
 diskMode:硬盘表示方式,YES时换算除1000,NO时换算除1024
 needUnit 是否需要携带单位
 */
+ (NSString *)stringFromSize:(uint64_t)theSize delimiter:(NSString *)delimiter diskMode:(BOOL)diskMode needUnit:(BOOL)needUnit{
    //修复整除问题（floatSize>=1000）及小数显示问题（整除不显示小数）。
    static const char units[] = { '\0', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y' };
    static int maxUnits = sizeof units - 1;
    
    int multiplier = (int)__binary_multiple__(diskMode);
    int exponent = 0;
    double bytes = theSize;
    while (bytes >= multiplier && exponent < maxUnits) {
        bytes /= multiplier;
        exponent++;
    }
//    NSLog(@"%s, bytes:%f",__FUNCTION__,bytes);
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    [formatter setMaximumIntegerDigits:3];
    [formatter setMaximumSignificantDigits:3];
    [formatter setUsesSignificantDigits:YES];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    //TODO: 修复用户反馈的一个BUG：size为999995129856，转换为string后变成0，目前没确定具体原因
    if((1000 - bytes)<0.1){
        bytes = 1;
        exponent++;
    }
//    NSNumber *number = [NSNumber numberWithDouble: bytes];
//    NSLog(@"%s, number:%@",__FUNCTION__,number);
//    NSString *stringNumber = [formatter stringFromNumber: number];
//    NSLog(@"%s, stringNumber:%@",__FUNCTION__,stringNumber);
//    NSString *result = [NSString stringWithFormat:@"%@%@%cB",stringNumber,delimiter,units[exponent]];
//    NSLog(@"%s, result:%@",__FUNCTION__,result);
    
    if (needUnit) {
        return [NSString stringWithFormat:@"%@%@%cB", [formatter stringFromNumber: [NSNumber numberWithDouble: bytes]], delimiter,units[exponent]];
    }else{
       return [NSString stringWithFormat:@"%@", [formatter stringFromNumber: [NSNumber numberWithDouble: bytes]]];
    }
}

+ (NSString *)stringFromSize:(uint64_t)theSize delimiter:(NSString *)delimiter diskMode:(BOOL)diskMode length:(uint8_t)length
{
    const NSString* sizeUnit[] = {@"B",@"KB",@"MB",@"GB",@"TB",@"PB"};
    
    NSInteger idx = 0;
    double floatSize = theSize;
    while (floatSize>1000 && idx < (sizeof(sizeUnit)/sizeof(sizeUnit[0])-1))
    {
        idx++;
        floatSize /= __binary_multiple__(diskMode);
    }
    
    if (idx == 0)
    {
        return [NSString stringWithFormat:@"%.0f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
    }else
    {
        NSString *formatString = [NSString stringWithFormat:@"%%.%df%%@%%@",MAX((int)length - ((int)log10(floatSize) + 1), 0)];
        return [NSString stringWithFormat:formatString,floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
    }
}

//最高只显示MB单位
+ (NSString *)stringFromMBSize:(uint64_t)theSize delimiter:(NSString *)delimiter diskMode:(BOOL)diskMode
{
    const NSString* sizeUnit[] = {@"B",@"KB",@"MB"};
    
    NSInteger idx = 0;
    double floatSize = theSize;
    while (floatSize>1000 && idx < (sizeof(sizeUnit)/sizeof(sizeUnit[0])-1))
    {
        idx++;
        floatSize /= __binary_multiple__(diskMode);
    }
    
    if (idx == 0)
    {
        return [NSString stringWithFormat:@"%3.0f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
    }else
    {
        if (floatSize > 100)
            return [NSString stringWithFormat:@"%.0f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
        else
            return [NSString stringWithFormat:@"%.1f%@%@",floatSize,delimiter?delimiter:@"",sizeUnit[idx]];
    }
}

@end

@implementation NSString (Speed)

+ (NSString *)stringFromNetSpeed:(CGFloat)value
{
    const float oneMB = 1024;
    float _value = 0;
    NSString * formatStr = nil;
    if (value > 1000)
    {
        _value = value / oneMB;
        formatStr = @" MB/s";
    }
    else
    {
        _value = value;
        formatStr = @" KB/s";
    }
    if (_value > 100)
        return [NSString stringWithFormat:@"%d%@", (int)_value, formatStr];
    else
        return [NSString stringWithFormat:@"%.1f%@", _value, formatStr];
}

+ (NSString *)stringFromNetSpeedWithoutSpacing:(CGFloat)value
{
    const float oneMB = 1024;
    float _value = 0;
    NSString * formatStr = nil;
    if (value > 1000)
    {
        _value = value / oneMB;
        formatStr = @"MB/s";
    }
    else
    {
        _value = value;
        formatStr = @"KB/s";
    }
    if (_value > 100)
        return [NSString stringWithFormat:@"%d%@", (int)_value, formatStr];
    else
        return [NSString stringWithFormat:@"%.1f%@", _value, formatStr];
}

@end


@implementation NSString (LMPath)

- (BOOL)isParentPath:(NSString *)childPath
{
    NSString *parentPath = self;
    //先去除未尾无意义的/符号
    while ([parentPath hasSuffix:@"/"])
    {
        parentPath = [parentPath substringToIndex:parentPath.length-1];
    }
    while ([childPath hasSuffix:@"/"])
    {
        childPath = [childPath substringToIndex:childPath.length-1];
    }
    
    //判断层级是否与满足父子关系
    NSArray *parentComponents = [parentPath pathComponents];
    NSArray *childComponents = [childPath pathComponents];
    
    if (parentComponents.count >= childComponents.count)
    {
        return NO;
    }
    
    //逐层比对
    for (int i=0; i<parentComponents.count; i++)
    {
        if (![parentComponents[i] isEqualToString:childComponents[i]])
        {
            return NO;
        }
    }
    return YES;
}


+(NSString *)getUserHomePath{
    NSString *homePath = nil;
    if (@available(macOS 10.12, *)) {
        NSURL *url = NSFileManager.defaultManager.homeDirectoryForCurrentUser;
        NSString *path = [url path];
        homePath = path;
    } else {
        homePath = NSHomeDirectory();
    }
    
//    NSLog(@"homepath = %@", homePath);
//    NSLog(@"homeUser = %@", NSUserName());
    
    NSArray *sepArr = [homePath componentsSeparatedByString:@"/"];
    
//    NSLog(@"separr = %@", sepArr);
    if ((sepArr == nil) || ([sepArr count] <= 2)) {
        return [NSString stringWithFormat:@"/Users/%@", NSUserName()];;
    }

    return [NSString stringWithFormat:@"/Users/%@", [sepArr objectAtIndex:2]];
}

@end

@implementation NSString(Truncates)

- (NSString *)truncatesString:(QMTruncatingMode)mode length:(NSInteger)length
{
    //非法的限制长度
    if (length <= 0)
    {
        return @"";
    }
    
    //本身已经在限制长度之内
    if (self.length <= length)
    {
        return [self copy];
    }
    
    //根据限制制定替换字符串
    NSString *truncateString = nil;
    if (length==1) {
        truncateString = @"";
    } else if (length==2) {
        truncateString = @".";
    } else if (length==3) {
        truncateString = @"..";
    } else {
        truncateString = @"...";
    }
    
    //替换长度是固定的,都是本身长度与替换符的长度和减去限制长度
    NSRange range;
    range.length = self.length+truncateString.length-length;
    if (mode == QMTruncatingHead)
    {
        range.location = 0;
    }else if (mode == QMTruncatingTail)
    {
        range.location = length-truncateString.length;
    }else
    {
        range.location = (length-truncateString.length)/2;
    }
    
    return [self stringByReplacingCharactersInRange:range withString:truncateString];
}

@end

@implementation NSString(Version)

- (NSString *)versionString
{
    NSString *versionRegular = @"\\d+(\\.\\d+)*";
    NSRange versionRange = [self rangeOfString:versionRegular options:NSRegularExpressionSearch];
    if (versionRange.location == NSNotFound)
    {
        return nil;
    }
    return [self substringWithRange:versionRange];
}

- (NSString *)buildVersionString
{
    //取出空格内的字符串
    NSString *regular = @"(?<=\\().*(?=\\))";
    NSRange range = [self rangeOfString:regular options:NSRegularExpressionSearch];
    if (range.location == NSNotFound)
    {
        return nil;
    }
    NSString *subString = [self substringWithRange:range];
    
    //再取出该字符串中的版本号
    return [subString versionString];
}

- (BOOL)compareVersion:(NSString*)otherVersion
{
    if ([self isEqualToString:otherVersion] || otherVersion == nil) {
        return NO;
    }
    BOOL isHigh = YES;
    NSArray *partArraySelf = [self componentsSeparatedByString:@"."];
    NSArray *partArrayOther = [otherVersion componentsSeparatedByString:@"."];
    for (int i = 0; i < partArraySelf.count; i++) {
        if (i > partArrayOther.count - 1) {
            return isHigh;
        } else {
            NSInteger partNumberSelf = [[partArraySelf objectAtIndex:i] integerValue];
            NSInteger partNumberOther = [[partArrayOther objectAtIndex:i] integerValue];
            if (partNumberSelf < partNumberOther) {
                isHigh = NO;
                return isHigh;
            } else if (partNumberSelf > partNumberOther) {
                return isHigh;
            }
            if ((i == partArraySelf.count - 1) && (i < partArrayOther.count - 1)) {
                i++;
                while (i <= partArrayOther.count - 1) {
                    NSInteger partNumberOther = [[partArrayOther objectAtIndex:i] integerValue];
                    if (partNumberOther > 0) {
                        isHigh = NO;
                        return isHigh;
                    }
                }
            }
        }
    }
    
    return isHigh;
}
@end


@implementation NSString (FindBundle)

- (NSString *)findBundlePath
{
    if (self.length == 0)
        return nil;
    
    if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:self])
        return self;
    
    NSString *parentPath = [self stringByDeletingLastPathComponent];
    if (parentPath.length == self.length)
        return nil;
    
    return [parentPath findBundlePath];
}

@end

@implementation NSString (Coding)

//转换包含\u这样的被unicode编码后的字符串(解析JSON时常遇上)
- (NSString *)replaceUnicode
{
    NSMutableString *replaceString = [NSMutableString stringWithString:self];
    
    [replaceString replaceOccurrencesOfString:@"\\u" withString:@"\\U" options:0 range:NSMakeRange(0, replaceString.length)];
    [replaceString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, replaceString.length)];
    [replaceString insertString:@"\"" atIndex:0];
    [replaceString appendString:@"\""];
    NSData *resultData = [replaceString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *returnString = [NSPropertyListSerialization propertyListFromData:resultData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    [returnString stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
    
    return [NSString stringWithString:returnString];
}

@end

@implementation NSString (MD5)
- (NSString *)md5String{
    //在使用CC_MD5的时候，不能传字符串的length长度，因为length经过了处理，在比如中文字符时会出问题
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data md5String];
}
@end



