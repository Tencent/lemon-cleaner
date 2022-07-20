//
// 
// Copyright (c) 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseBrowserPrivacyDataManager.h"

@interface ChromePrivacyDataManager : BaseBrowserPrivacyDataManager

+ (ChromePrivacyDataManager *)sharedManagerWithDataPath:(NSString*)dataPath;

+ (NSArray<NSString *> *)getBrowserDataPathArray;

+ (NSString *)getChromeDataDefaultPath; // ~/Library/Application Support/Google/Chrome/Default

+ (NSString *) tryGetAccountNameByPath:(NSString*)path; // 可能为空
@end
