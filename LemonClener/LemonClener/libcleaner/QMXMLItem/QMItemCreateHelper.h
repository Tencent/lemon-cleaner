//
//  QMItemCreateHelper.h
//  LemonClener
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMCategoryItem.h"

@interface QMItemCreateHelper : NSObject

//创建一个模拟的 soft QMCategorySubItem 规则
+(QMCategorySubItem *)createSoftAdaptCategorySubItemWithId:(NSString *)subCateId DisplayName:(NSString *)appDisplayName searchNane:(NSString *)appSearchName bundleId:(NSString *)bundleId appPath:(NSString *)appPath;

//通过已安装列表来创建模拟规则
+(void)createAllSoftAdaptCategorySubItemWithInstallArr:(NSDictionary *)installBundleIdDic curCategoryItem:(QMCategoryItem *)categoryItem;

//判断是否有中文
+ (BOOL)isIncludeChineseInString:(NSString*)str;

@end
