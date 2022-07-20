//
//  LMAppSandboxHelper.h
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMActionItem.h"

@interface LMAppSandboxHelper : NSObject

+(LMAppSandboxHelper *)shareInstance;

//没有适配到的软件 在扫描中进行查看 防止刚上来获取卡主主线程
-(SandboxType)getAppSandboxTypeInScanWithBundleId:(NSString *)bundleId appPath:(NSString *)appPath;

//通过appPath --》 bool
-(SandboxType)getAppSandboxInfoWithBundleId:(NSString *)bundleId appPath:(NSString *)appPath;

@end
