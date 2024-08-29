//
//  QMUnityRepo.m
//  LemonClener
//
//  Created by watermoon on 2024/8/19.
//  Copyright © 2024 Tencent. All rights reserved.
//

// 扫描 Unity 仓库的临时目录

#import "QMUnityScan.h"
#import "QMFilterParse.h"
#import "QMResultItem.h"
#import <Foundation/Foundation.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/NSScreen+Extension.h>

@implementation QMUnityScan
@synthesize delegate;

-(void)scanArtifacts:(QMActionItem *)actionItem {
    
}

-(void)scanBuilds:(QMActionItem *)actionItem {
    
}

-(void)scanStevedore:(QMActionItem *)actionItem {
    
}

-(void)scanPath:(NSString *) path actionItem:(QMActionItem *)actionItem {
    NSString *shellString = [NSString stringWithFormat:@"mdfind -onlyin %@ kind:folders | egrep \"/Logs$|/Library$\|/obj$|/build$|/Build$\"", path];
    NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
    if (retString == nil || [retString isEqual:@""])
        return;

    NSArray *pathItemArray = [retString componentsSeparatedByString:@"\n"];
    if ((pathItemArray == nil) || ([pathItemArray count] == 0)) {
        return;
    }

    uint64_t size = [path length];
    NSString *projFolder = [path lastPathComponent];
    for (int i = 0; i < [pathItemArray count]; i++) {
        NSString *result = [pathItemArray objectAtIndex:i];
        if ([result length] == 0)
            continue;

        NSRange range = [result rangeOfString:@"/" options:NSBackwardsSearch];
        if (range.location == NSNotFound)
            continue;
        if (range.location != size)
            continue;

        NSLog(@"fileName=%@", result);
        QMResultItem *resultItem = [[QMResultItem alloc] initWithPath: result];
        NSString *foler = [result lastPathComponent];
        resultItem.title = [NSString stringWithFormat:@"%@/%@", projFolder, foler];
        resultItem.cleanType = actionItem.cleanType;

        // 添加结果
        if (resultItem)
            [resultItem addResultWithPath:result];
        if ([resultItem resultFileSize] == 0) {
            // NSLOG
            resultItem = nil;
        }
        if ([delegate scanProgressInfo:(i+1.0) / [pathItemArray count] scanPath: result resultItem:resultItem])
            break;
    }
}

-(void)scanProj:(QMActionItem *)actionItem {
    NSLog(@"scanning unity project...\n");
    QMFilterParse * filterParse = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [filterParse enumeratorAtFilePath:actionItem];//通过扫描规则和过滤规则，返回所有路径

    for (int i = 0; i < [pathArray count]; i++) {
        NSString *path = [pathArray objectAtIndex:i];

        [self scanPath: path actionItem: actionItem];
    }
}

@end
