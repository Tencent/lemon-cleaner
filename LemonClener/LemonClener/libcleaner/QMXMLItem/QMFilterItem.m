//
//  QMFilterItem.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMFilterItem.h"
#import "QMXMLItemDefine.h"
#import "QMCleanUtils.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/McCoreFunction.h>

@implementation QMFilterItem
@synthesize filterID;
@synthesize column;
@synthesize relation;
@synthesize value;
@synthesize action;
@synthesize andFilterItem;
@synthesize orFilterItem;
@synthesize logicLevel;

-(id)copyWithZone:(NSZone *)zone{
    QMFilterItem *copy = [[QMFilterItem alloc] init];
    if (copy) {
        copy.filterID = [self.filterID mutableCopy];
        copy.column = [self.column mutableCopy];
        copy.relation = [self.relation mutableCopy];
        copy.value = [self.value mutableCopy];
        copy.action = [self.action mutableCopy];
        copy.andFilterItem = [self.andFilterItem copy];
        copy.orFilterItem = [self.orFilterItem copy];
        copy.logicLevel = self.logicLevel;
    }
    
    return copy;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    QMFilterItem *copy = [[QMFilterItem alloc] init];
    if (copy) {
        copy.filterID = [self.filterID mutableCopy];
        copy.column = [self.column mutableCopy];
        copy.relation = [self.relation mutableCopy];
        copy.value = [self.value mutableCopy];
        copy.action = [self.action mutableCopy];
        copy.andFilterItem = [self.andFilterItem copy];
        copy.orFilterItem = [self.orFilterItem copy];
        copy.logicLevel = self.logicLevel;
    }
    
    return copy;
}

- (BOOL)checkFilterWithFilePath:(NSString *)path
{
//    if ([filterID isEqualToString:@"260"])
//        NSLog(@"aa");
    BOOL retValue = YES;
    if ([column isEqualToString:kXMLKeyFileName]
        || [column isEqualToString:kXMLKeyLanguage]
        || [column isEqualToString:kXMLKeyFilePath]
        || [column isEqualToString:@"bundleid"])
    {
        // is contenins mactch 方式过滤字符串
        NSString * compareValue = nil;
        NSString * tempValue = value;
        if ([column isEqualToString:kXMLKeyFileName])
        {
            // 比较文件名
            compareValue = [path lastPathComponent];
        }
        else if ([column isEqualToString:kXMLKeyFilePath])
        {
            // 比较路径
            compareValue = path;
            if ([McCoreFunction isAppStoreVersion]){
                if ([tempValue containsString:@"~"]) {
                    NSString *homePath = [NSString getUserHomePath];
                    NSString *newValue = [value stringByReplacingOccurrencesOfString:@"~" withString:@""];
                    //NSLog(@"tempValue: %@, \nhomePath: %@", tempValue, homePath);
                    tempValue = [NSString stringWithFormat:@"%@%@", homePath, newValue];
                }else{
                    tempValue = [value stringByStandardizingPath];
                }
            } else {
                tempValue = [value stringByStandardizingPath];
            }
        }
        else if ([column isEqualToString:kXMLKeyLanguage])
        {
            // 比较语言key
            compareValue = path;
        }
        else
        {
            compareValue = [[NSBundle bundleWithPath:path] bundleIdentifier];
        }
        
        if ([relation isEqualToString:@"is"])
        {
            if (![compareValue isEqualToString:tempValue])
                retValue = NO;
        }
        else if ([relation isEqualToString:@"contains"])
        {
            if ([compareValue rangeOfString:tempValue].length == 0)
                retValue = NO;
        }
        else if ([relation isEqualToString:@"match"])
        {
            if (![QMCleanUtils assertRegex:tempValue matchStr:compareValue])
                retValue = NO;
        }
        else if ([relation isEqualToString:@"begin with"])
        {
            if (![compareValue hasPrefix:tempValue])
                retValue = NO;
        }
        else if ([relation isEqualToString:@"end with"])
        {
            NSRange range = [compareValue rangeOfString:tempValue];
            if (range.length == 0 || (range.location + range.length != compareValue.length))
                retValue = NO;
        }
    }
    else if ([column isEqualToString:@"filesize"])
    {
        // 比较文件大小
        NSUInteger fileSize = [QMCleanUtils caluactionSize:path];
        if ([relation isEqualToString:@"greater"])
        {
            if (fileSize < [value longLongValue])
                retValue = NO;
        }
    }
    else if ([column isEqualToString:@"app"])
    {
        if ([relation isEqualToString:@"is"] && [value isEqualToString:@"signed"] && ![QMCleanUtils isBinarySignCode:path])
            retValue = NO;
    }else if([column isEqualToString:@"time"])
    {
        NSTimeInterval createTime = [QMCleanUtils createTime:path];
        NSTimeInterval lastModifyTime = [QMCleanUtils lastModificateionTime:path];
//        NSTimeInterval lastAccessTime = [QMMFCleanUtils lastAccessTime:path];
        NSTimeInterval recentTime = createTime > lastModifyTime ? createTime : lastModifyTime;
//        recentTime = recentTime > lastAccessTime ? recentTime : lastAccessTime;
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSUInteger extraTime = currentTime - recentTime;
        if ([relation isEqualToString:@"greater"] && (recentTime != 0))
        {
            if ((extraTime > 0) && (extraTime <= [value longLongValue] * 24 * 60 * 60)) {
                retValue = NO;
            }
        }else if([relation isEqualToString:@"smaller"] && (recentTime != 0)){
            if ((extraTime > 0) && (extraTime >= [value longLongValue] * 24 * 60 * 60)) {
                retValue = NO;
            }
        }
    }
    if (action && [action isEqualToString:@"exclude"])
    {
        retValue = !retValue;
    }
    return retValue;
}

- (BOOL)checkFilterWithPath:(NSString *)path
{
    if ([column hasPrefix:@"sub"])
    {
        NSFileManager * fm = [NSFileManager defaultManager];
        NSDirectoryEnumerator * _pathEnumerator = [fm enumeratorAtPath:path];
        NSMutableArray * subFileArray = [NSMutableArray array];
        
        NSString * comparePath = value;
        
        if ([column isEqualToString:@"subfilepath"]){
            if ([McCoreFunction isAppStoreVersion]){
                if ([comparePath containsString:@"~"]) {
                    NSString *homePath = [NSString getUserHomePath];
                    NSString *newPath = [comparePath stringByReplacingOccurrencesOfString:@"~" withString:@""];
                    comparePath = [NSString stringWithFormat:@"%@%@", homePath, newPath];
                }else{
                    //                tempValue = [value stringByStandardizingPath];
                    comparePath = [comparePath stringByStandardizingPath];
                }
            } else {
                comparePath = [comparePath stringByStandardizingPath];
            }
        }
        
        while (YES)
        {
            NSString * curObject = [_pathEnumerator nextObject];
            if (curObject == nil)
                break;
            if ([curObject hasPrefix:@"."])
                continue;
            NSString * curPath = [path stringByAppendingPathComponent:curObject];
            [subFileArray addObject:curPath];
            if ([column isEqualToString:@"subfilecount"])
            {
                if ([subFileArray count] > [value integerValue])
                    return YES;
            }
            if ([column isEqualToString:@"subfilepath"])
            {
                if ([curPath isEqualToString:comparePath])
                    return YES;
            }
        }
        if ([column isEqualToString:@"subfilecount"])
        {
            if ([subFileArray count] > [value integerValue])
                return YES;
        }
    }
    else
    {
        return [self checkFilterWithFilePath:path];
    }
    return NO;
}

@end
