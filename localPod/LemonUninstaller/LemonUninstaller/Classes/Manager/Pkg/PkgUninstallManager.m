//
// 
// Copyright (c) 2019 Tencent. All rights reserved.
//

#import "PkgUninstallManager.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>


static NSArray<NSString *> *notSystemPkgList = nil;

@implementation PkgUninstallManager {

}

+ (instancetype)shared {
    static dispatch_once_t once;
    static PkgUninstallManager *manager = nil;
    dispatch_once(&once, ^{
        manager = [[PkgUninstallManager alloc] init];
    });

    return manager;
}


- (PkgUninstallProvider *)getProviderWithAppBundleId:(NSString *)appBundleId {

    if ([appBundleId isEqualToString:@"com.paragon-software.ntfs.fsapp"]) {
        // ntfs
        
        //   注意: NTFS 自带卸载工具. 需要 root权限执行: 目录:
        //  /Library/Application Support/Paragon Software/com.paragon-software.ntfs.uninstall
        NSString *pkgBundleId = @"com.paragon-software.pkg.ntfs";
        NSString *keyWord = @"ntfs";
        PkgUninstallProvider *provider = [[PkgUninstallProvider alloc] initWithPkgBundleId:pkgBundleId withKeyWording:keyWord];
        return provider;
    }
    
    // Bee cut
    if ([appBundleId isEqualToString:@"com.apowersoft.BeeCut-mac"]) {
        
        // 现在看 Bee cut 没有额外的残留文件 需要用到pkg 卸载. 现只用来清理 pkg 注册信息
        NSString *pkgBundleId = @"MacBeeCut.apowersoft.com";
        NSString *keyWord = @"BeeCut";
        PkgUninstallProvider *provider = [[PkgUninstallProvider alloc] initWithPkgBundleId:pkgBundleId withKeyWording:keyWord];
        return provider;
    }
    
    if ([appBundleId isEqualToString:@"com.cisco.anyconnect.gui"]) {
        
        NSString *pkgBundleId = @"com.cisco.pkg.anyconnect.vpn";
        NSString *keyWord = @"cisco";
        PkgUninstallProvider *provider = [[PkgUninstallProvider alloc] initWithPkgBundleId:pkgBundleId withKeyWording:keyWord];
        return provider;
    }

    return nil;
}


// pkgutil --pkgs
// 一次整体扫描只执行一次
+ (NSArray<NSString *> *)pkgList {
    return notSystemPkgList;
}


+ (void)searchAllPkgList {
    NSString *pkgListCmd = @"pkgutil --pkgs";
    NSString *resultList = [QMShellExcuteHelper excuteCmd:pkgListCmd];

    NSMutableArray *notSystemPkgs = [NSMutableArray array];
    if (resultList || resultList.length > 0) {
        NSArray<NSString *> *list = [resultList componentsSeparatedByString:@"\n"];
        BOOL isSuccess = FALSE;
        for (NSString *item in list) {
            if ([item containsString:@"com.apple"]) {  //pkgList 一定有系统的package.
                isSuccess = YES;
            } else {
                [notSystemPkgs addObject:item];
            }
        }

        if (isSuccess) {
            notSystemPkgList = [notSystemPkgs copy];
        }
    }
}


// 每次清理完成,清理 pkg list等,防止 pkg 信息更新.
+ (void)clearAfterFinish {
    notSystemPkgList = nil;
}


@end
