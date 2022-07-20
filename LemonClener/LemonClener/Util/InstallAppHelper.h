//
//  InstallAppHelper.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InstallAppHelper : NSObject

//用来获取已安装的应从，从而生成自动软件适配的subCateItem
+(NSMutableDictionary *)getInstallBundleIds;

@end
