//
//  QMItemCreateHelper.m
//  LemonClener
//

//  Copyright © 2019年 Tencent. All rights reserved.
//
//  代码自动适配 软甲产生的缓存和logs存放的位置
//

#import "QMItemCreateHelper.h"
#import "QMActionItem.h"
#import "LMAppSandboxHelper.h"

typedef NS_ENUM(NSUInteger, CreateActionItemType) {
    CreateActionItemTypeCache,
    CreateActionItemTypeLogs,
    CreateActionItemTypeData,
};

@implementation QMItemCreateHelper

///添加未适配的软件
+(void)createAllSoftAdaptCategorySubItemWithInstallArr:(NSDictionary *)installBundleIdDic curCategoryItem:(QMCategoryItem *)categoryItem{
    
    //字典不合法 直接返回
    if ((installBundleIdDic == nil) || ([[installBundleIdDic allKeys] count] == 0)) {
        return;
    }
    //使用的id必须是能够唯一代表这款软件  否则无法做勾选、发勾选 记住操作
    for (NSString *bundleId in [installBundleIdDic allKeys]) {
        //先屏蔽苹果软件
        if ([bundleId containsString:@"com.apple"]) {
            continue;
        }
        QMCategorySubItem *subCateItem = [QMItemCreateHelper processInfoToCreateSubItem:bundleId installBundleDic:installBundleIdDic];
        if (subCateItem == nil) {
            continue;
        }
        [categoryItem addSubCategoryItem:subCateItem];

    }
    for (NSString *bundleId in [installBundleIdDic allKeys]) {
        //先屏蔽非苹果软件
        if (![bundleId containsString:@"com.apple"]) {
            continue;
        }
        
        if ([bundleId containsString:@"com.apple.logic"]) {
            continue;
        }
        
        QMCategorySubItem *subCateItem = [QMItemCreateHelper processInfoToCreateSubItem:bundleId installBundleDic:installBundleIdDic];
        if (subCateItem == nil) {
            continue;
        }
        [categoryItem addSubCategoryItem:subCateItem];
    }
}

+(QMCategorySubItem *)processInfoToCreateSubItem:(NSString *)bundleId installBundleDic:(NSDictionary *)installBundleDic{
    //过滤浏览器软件
    if ([bundleId isEqualToString:@"com.apple.Safari"] || [bundleId isEqualToString:@"com.google.Chrome"] || [bundleId isEqualToString:@"com.operasoftware.Opera"] || [bundleId isEqualToString:@"org.mozilla.firefox"] || [bundleId isEqualToString:@"com.tencent.QQBrowser"]) {
        return nil;
    }
    //用来搜索路径使用
    NSString *appSearchName = [NSBundle bundleWithIdentifier:bundleId].infoDictionary[(NSString *)kCFBundleNameKey];
    //用来显示应用名
    NSString *appDisplayname = [NSBundle bundleWithIdentifier:bundleId].localizedInfoDictionary[(NSString *)kCFBundleNameKey];
    
    if (appDisplayname == nil || [appDisplayname isKindOfClass:[NSNull class]]) {
        appDisplayname = appSearchName;
    }
    
    if (appDisplayname == nil || [appDisplayname isEqualToString:@""]) {
        return nil;
    }
    if (![installBundleDic isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    QMCategorySubItem *subCateItem = [QMItemCreateHelper createSoftAdaptCategorySubItemWithId:bundleId DisplayName:appDisplayname searchNane:appSearchName bundleId:bundleId appPath:[installBundleDic objectForKey:bundleId]];
    return subCateItem;
}

+(QMCategorySubItem *)createSoftAdaptCategorySubItemWithId:(NSString *)subCateId DisplayName:(NSString *)appDisplayName searchNane:(NSString *)appSearchName bundleId:(NSString *)bundleId appPath:(NSString *)appPath{
    
    QMCategorySubItem *subItem = [[QMCategorySubItem alloc] init];
    
    //组装数据
    subItem.subCategoryID = subCateId;
    subItem.bundleId = subCateId;
    subItem.title = appDisplayName;
    subItem.tips = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMItemCreateHelper_createSoftAdaptCategorySubItemWithId_1553048057_1", nil, [NSBundle bundleForClass:[self class]], @""), appDisplayName];
    subItem.fastMode = YES;
    subItem.showAction = YES;
    if ([bundleId isEqualToString:@"com.google.android.studio"] || [bundleId isEqualToString:@"com.jetbrains.intellij"] || [bundleId isEqualToString:@"com.jetbrains.PhpStorm"]) {
        subItem.recommend = NO;
        subItem.fastMode = NO;
    }
    
    //缓存
    QMActionItem *cacheActionItem = [QMItemCreateHelper createActionItemWithId:[NSString stringWithFormat:@"%@1", subCateId] appDisplayName:appDisplayName appSearchName:appSearchName createActionItemType:CreateActionItemTypeCache bundleId:bundleId appPath:appPath];
    // 自适配软件，不清理sketch的缓存
    if ([bundleId containsString:@"com.bohemiancoding.sketch"]) {
        cacheActionItem.recommend = NO;
    }
    [subItem addActionItem:cacheActionItem];
    
    //日志
    QMActionItem *logActionItem = [QMItemCreateHelper createActionItemWithId:[NSString stringWithFormat:@"%@2", subCateId] appDisplayName:appDisplayName appSearchName:appSearchName createActionItemType:CreateActionItemTypeLogs bundleId:bundleId appPath:appPath];
    [subItem addActionItem:logActionItem];
    
    return subItem;
}

+(QMActionItem *)createActionItemWithId:(NSString *)actionId appDisplayName:(NSString *)appDisplayName appSearchName:(NSString *)appSearchName createActionItemType:(CreateActionItemType)type bundleId:(NSString *)bundleId appPath:(NSString *)appPath{
    QMActionItem *actionItem = [[QMActionItem alloc] init];
    actionItem.actionID = actionId;
    //在这里进行区分是否是sandbox app
    SandboxType sandboxType = [[LMAppSandboxHelper shareInstance] getAppSandboxInfoWithBundleId:bundleId appPath:appPath];
    
    if (type == CreateActionItemTypeCache) {
        actionItem.type = QMActionSoftAppCacheType;
        actionItem.bundleID = bundleId;
        actionItem.appPath = appPath;
        actionItem.sandboxType = sandboxType;
        actionItem.title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMItemCreateHelper_createActionItemWithId_actionItem_1", nil, [NSBundle bundleForClass:[self class]], @""), appDisplayName];
        //添加扫描路径 包括SystemDir
//        if (isSandbox) {
//            QMActionPathItem *sandboxPathItem = [QMItemCreateHelper createPathItemWithType:@"abs" path:[NSString stringWithFormat:@"~/Library/Containers/%@/Data/Library/Caches/", bundleId] bundleId:bundleId];
//            [actionItem addActionPathItem:sandboxPathItem];
//            actionItem.sandboxType = SandboxTypeYes;
//        }else{
//            //~/Library/Caches目录
//            QMActionPathItem *cachesBundlePathItem = [QMItemCreateHelper createPathItemWithType:@"abs" path:[NSString stringWithFormat:@"~/Library/Caches/%@/", bundleId] bundleId:bundleId];
//            [actionItem addActionPathItem:cachesBundlePathItem];
////            QMActionPathItem *cachesNamePathItem = [QMItemCreateHelper createPathItemWithType:@"abs" path:[NSString stringWithFormat:@"~/Library/Caches/%@/", appSearchName] bundleId:bundleId];
//            [actionItem addActionPathItem:cachesNamePathItem];
//            actionItem.sandboxType = SandboxTypeNot;
//            actionItem.appSearchName = appSearchName;
//        }
//        QMActionPathItem *systemPathItem = [QMItemCreateHelper createPathItemWithType:@"special" path:@"SystemTempDir" bundleId:bundleId];
//        [actionItem addActionPathItem:systemPathItem];
        
    }else if (type == CreateActionItemTypeLogs){
        actionItem.type = QMActionFileType;
        actionItem.title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMItemCreateHelper_createActionItemWithId_actionItem_2", nil, [NSBundle bundleForClass:[self class]], @""), appDisplayName];
        if (sandboxType == SandboxTypeYes) {
            QMActionPathItem *sandboxBundlePathItem = [QMItemCreateHelper createPathItemWithType:@"abs" path:[NSString stringWithFormat:@"~/Library/Containers/%@/Data/Library/Logs/", bundleId] bundleId:bundleId];
            [actionItem addActionPathItem:sandboxBundlePathItem];
        }else if(sandboxType == SandboxTypeNot){
            QMActionPathItem *logsBundlePathItem = [QMItemCreateHelper createPathItemWithType:@"abs" path:[NSString stringWithFormat:@"~/Library/Logs/%@/", bundleId] bundleId:bundleId];
            [actionItem addActionPathItem:logsBundlePathItem];
        }else{
            QMActionPathItem *sandboxBundlePathItem = [QMItemCreateHelper createPathItemWithType:@"abs" path:[NSString stringWithFormat:@"~/Library/Containers/%@/Data/Library/Logs/", bundleId] bundleId:bundleId];
            [actionItem addActionPathItem:sandboxBundlePathItem];
            QMActionPathItem *logsBundlePathItem = [QMItemCreateHelper createPathItemWithType:@"abs" path:[NSString stringWithFormat:@"~/Library/Logs/%@/", bundleId] bundleId:bundleId];
            [actionItem addActionPathItem:logsBundlePathItem];
        }
    }
    
    return actionItem;
}

+(QMActionPathItem *)createPathItemWithType:(NSString *)type path:(NSString *)path bundleId:(NSString *)bundleId{
    QMActionPathItem *pathItem = [[QMActionPathItem alloc] init];
    pathItem.type = type;
    pathItem.value = path;
    pathItem.level = 1;
    if (![type isEqualToString:@"abs"]) {
        pathItem.value1 = bundleId;
    }
    
    return pathItem;
}

+ (BOOL)isIncludeChineseInString:(NSString*)str{
    for (int i=0; i<str.length; i++) {
        unichar ch = [str characterAtIndex:i];
        if (0x4E00 <= ch  && ch <= 0x9FA5) {
            return YES;
        }
    }
    return NO;
}

@end
