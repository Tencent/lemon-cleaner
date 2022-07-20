//
//  MdlsToolsHelper.m
//  LemonClener
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "MdlsToolsHelper.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>

@implementation MdlsToolsHelper

+(NSInteger)getAppSizeByPath:(NSString *)path andFileType:(NSString *)type{
    if ((path == nil) || [path isEqualToString:@""]) {
        return 0;
    }
    //目前trash中app无法使用这种方式获取到size
    if ([path containsString:@".Trash"]) {
        return 0;
    }
    //不以type结尾 直接返回0
    if (![[[path lastPathComponent] pathExtension] isEqualToString:type]) {
        return 0;
    }
    NSString *outString = [QMShellExcuteHelper excuteCmd:[NSString stringWithFormat:@"mdls \"%@\"", path]];
    if ((outString == nil) || [outString isEqualToString:@""]) {
        return 0;
    }
    NSArray *attrArray = [outString componentsSeparatedByString:@"\n"];
    NSString *phySize = nil;
    for (NSString *tempItemAttr in attrArray) {
        if ([tempItemAttr containsString:@"kMDItemPhysicalSize"]) {
            phySize = tempItemAttr;
        }
    }
    if (phySize == nil) {
        return 0;
    }
    
    NSArray *phySizeArr = [phySize componentsSeparatedByString:@"="];
    if ([phySizeArr count] <= 1) {
        return 0;
    }
    
    NSString *sizeString = [phySizeArr objectAtIndex:1];
    return [sizeString integerValue];
}

@end
