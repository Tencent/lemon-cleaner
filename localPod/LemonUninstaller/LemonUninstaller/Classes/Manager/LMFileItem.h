//
//  LMFileItem.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, LMFileType) {
    LMFileTypeBundle = 1,
    LMFileTypeSupport,
    LMFileTypeCache,
    LMFileTypePreference,
    LMFileTypeState,
    LMFileTypeReporter,
    LMFileTypeLog,
    LMFileTypeSandbox,
    LMFileTypeDaemon,
    LMFileTypeLoginItem, // 第10项

    LMFileTypeKextWithBundleId,  // kext以 bundleId 形式展示(brew 卸载模块提供)
    LMFileTypeKextWithPath,      // kext以 path 形式展示(pkg 卸载模块提供)
    LMFileTypeSignal,
    LMFileTypeFileSystem,
    LMFileTypePreferencePane,

    LMFileTypeOther

};



@interface LMFileItem : NSObject

+ (LMFileItem *)itemWithPath:(NSString *)path withType:(LMFileType)type;

@property(nonatomic, strong) NSString *path;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSImage *icon;
@property(nonatomic, readonly) NSInteger size;
@property(nonatomic, assign) BOOL isSelected;
@property(nonatomic, assign) LMFileType type;
@property(nonatomic, assign) BOOL isDeleted;

+ (BOOL)needShowPath:(LMFileItem *)fileItem;

+ (NSString *)getLMFileTypeName:(LMFileType)type;

@end

NS_ASSUME_NONNULL_END
