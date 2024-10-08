//
//  QMXcodeScan.m
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

//使用mdls来加速遍历结果 加速扫描效率

#import "QMXcodeScan.h"
#import "QMFilterParse.h"
#import "QMResultItem.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/NSString+Extension.h>

@implementation QMXcodeScan
@synthesize delegate;

//
-(void)scanDerivedDataApp:(QMActionItem *)actionItem{
    [self __scanDerivedDataApp:actionItem];
    [self scanActionCompleted];
}

-(void)__scanDerivedDataApp:(QMActionItem *)actionItem{
    NSString *shellString = @"mdfind -onlyin ~/Library/ \"kMDItemContentType=='com.apple.application-bundle'\"";
    NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
    if (retString == nil || [retString isEqualToString:@""]) {
        return;
    }
    NSArray *pathItemArray = [retString componentsSeparatedByString:@"\n"];
    if ((pathItemArray == nil) || ([pathItemArray count] == 0)) {
        return;
    }
    for (int i = 0; i < [pathItemArray count]; i++)
    {
        NSString *result = [pathItemArray objectAtIndex:i];
        if (![result containsString:@"/Library/Developer/Xcode/DerivedData/"]) {
            continue;
        }
        QMResultItem * resultItem = nil;
        NSString * fileName = [result lastPathComponent];
        NSString * appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:fileName];
        if (appPath)
        {
            resultItem = [[QMResultItem alloc] initWithPath:appPath];
            resultItem.path = result;
        }
        else
        {
            resultItem = [[QMResultItem alloc] initWithPath:result];
        }
        resultItem.cleanType = actionItem.cleanType;
        
        // 添加结果
        if (resultItem) [resultItem addResultWithPath:result];
        if ([resultItem resultFileSize] == 0) {
            resultItem = nil;
        }
        if ([delegate scanProgressInfo:(i + 1.0) / [pathItemArray count] scanPath:result resultItem:resultItem])
            break;
    }
}

-(void)scanArchives:(QMActionItem *)actionItem{
    [self __scanArchives:actionItem];
    [self scanActionCompleted];
}

-(void)__scanArchives:(QMActionItem *)actionItem{
    NSString *shellString = @"mdfind -onlyin ~/Library/ \"kMDItemContentType=='com.apple.xcode.archive'\"";
    NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
    if (retString == nil || [retString isEqualToString:@""]) {
        return;
    }
    NSArray *pathItemArray = [retString componentsSeparatedByString:@"\n"];
    if ((pathItemArray == nil) || ([pathItemArray count] == 0)) {
        return;
    }
    for (int i = 0; i < [pathItemArray count]; i++)
    {
        NSString *result = [pathItemArray objectAtIndex:i];
        if (![result containsString:@"/Library/Developer/Xcode/Archives/"]) {
            continue;
        }
        QMResultItem * resultItem = nil;
        NSString * fileName = [result lastPathComponent];
        NSString * appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:fileName];
        if (appPath)
        {
            resultItem = [[QMResultItem alloc] initWithPath:appPath];
            resultItem.path = result;
        }
        else
        {
            resultItem = [[QMResultItem alloc] initWithPath:result];
        }
        resultItem.cleanType = actionItem.cleanType;
        
        // 添加结果
        if (resultItem) [resultItem addResultWithPath:result];
        if ([resultItem resultFileSize] == 0) {
            resultItem = nil;
        }
        if ([delegate scanProgressInfo:(i + 1.0) / [pathItemArray count] scanPath:result resultItem:resultItem])
            break;
    }
}

@end
