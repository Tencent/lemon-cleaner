//
//  PkgUninstallProvider.h
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PkgFileNode.h"
NS_ASSUME_NONNULL_BEGIN

@interface PkgUninstallProvider : NSObject

- (id)initWithPkgBundleId:(NSString *)pkgBundleId withKeyWording:(NSString *)keyWord;

- (void)searchAllItems;

- (NSArray *)searchBundles;

- (NSArray *)scanKext;

- (NSArray *)searchFileSystem;

- (NSArray *)searchPreferencePane;

- (NSArray *)scanSupports;

- (NSArray *)scanLaunchDaemons;

- (NSArray *)scanOthers;

- (BOOL) removePkgInfo;

@end

NS_ASSUME_NONNULL_END


// 整体步骤 Shell 版整理

// 1.寻找 pkg 的 bundleid
// pkgutil --pkgs | grep Bee

// 2. 寻找安装时的文件
// pkgutil --only-files --files  com.paragon-software.pkg.ntfs
// pkgutil --files 所有文件夹及文件
// pkgutil --only-dirs  --files    List only directories (not files) in --files listing


// 3.(pkgutil --pkg-info "$PKGNAME"  寻找 location,定位字符串.


// 4. 组建文件树, 把文件挂载到文件夹下.

// 5. 递归文件树, 设置所有文件夹节点是否已经列出了所有的子项

// 6. 递归文件树,找出能安全删除的所有文件路径

// 7. 按照文件分类提供给外部使用(只提供能安全删除的)



