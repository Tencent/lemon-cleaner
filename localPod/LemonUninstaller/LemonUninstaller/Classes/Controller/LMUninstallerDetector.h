//
//  LMUninstallerDetector.h
//  LemonUninstaller
//
//  Created by tencent on 2025/9/26.
//

#import <Foundation/Foundation.h>
#import "LMLocalApp.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMUninstallerDetector : NSObject

/**
 * 获取单例实例
 */
+ (instancetype)sharedInstance;

/**
 * 检测应用是否有专用卸载程序
 * @param app 要检测的应用
 * @return 卸载程序路径，如果没有则返回nil
 */
- (nullable NSString *)detectUninstallerForApp:(LMLocalApp *)app;

/**
 * 在指定路径中查找卸载程序
 * @param path 搜索路径
 * @param appName 应用名称
 * @return 找到的卸载程序路径数组
 */
- (NSArray<NSString *> *)findUninstallersInPath:(NSString *)path appName:(NSString *)appName;

/**
 * 验证卸载程序是否有效
 * @param uninstallerPath 卸载程序路径
 * @return 是否有效
 */
- (BOOL)isValidUninstaller:(NSString *)uninstallerPath;





@end

NS_ASSUME_NONNULL_END
