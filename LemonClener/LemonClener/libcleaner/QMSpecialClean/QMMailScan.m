//
//  QMMailScan.m
//  LemonClener
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "QMMailScan.h"
#import "QMResultItem.h"

@interface QMMailScan()
{
    QMCleanType _cleanType;
}
@end

@implementation QMMailScan

- (void)scanMailAttachments:(QMActionItem *)actionItem{
    [self __scanMailAttachments:actionItem];
    [self scanActionCompleted];
}

- (void)__scanMailAttachments:(QMActionItem *)actionItem{
    // 传入的 path 需要是 ~/Library/Mail
    // 返回的array可能为 nil
    // 特别注意 mail 的 item 默认是不选中的,需要用户主动选中才能清除
    _cleanType = actionItem.cleanType;
    QMActionPathItem *pathItem = [actionItem.pathItemArray objectAtIndex:0];
    NSString *standardPath = [pathItem.value stringByStandardizingPath];
    [QMMailUtil getMailAttachMentPathArray:standardPath withDelegate:self];
}


- (void)mailScanProcess:(double)process path:(NSString *) path pathResult:(NSArray *)paths{
    if(self.delegate){
        if ((paths == nil) || ([paths count] == 0)) {
            if ([self.delegate scanProgressInfo:process scanPath:path resultItem:nil]) {
                return;
            }
        }else{
            for (NSString *tempPath in paths) {
                QMResultItem * resultItem = nil;
                NSString * fileName = [tempPath lastPathComponent];
                NSString * appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:fileName];
                if (appPath)
                {
                    resultItem = [[QMResultItem alloc] initWithPath:appPath];
                    resultItem.path = path;
                }
                else
                {
                    resultItem = [[QMResultItem alloc] initWithPath:tempPath];
                }
                resultItem.cleanType = _cleanType;
                
                // 添加结果
                if (resultItem) [resultItem addResultWithPath:tempPath];
                if([self.delegate scanProgressInfo:process scanPath:tempPath resultItem:resultItem]){
                    return;
                }
            }
            
        }
    }
}

@end
