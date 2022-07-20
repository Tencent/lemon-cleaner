//
//  LMFileItem.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMFileItem.h"
#import <Appkit/Appkit.h>
#import <QMCoreFunction/NSFileManager+Extension.h>
#import <QMCoreFunction/MdlsToolsHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>


@interface LMFileItem () {
    NSNumber *_size;
}

@end

@implementation LMFileItem

+ (LMFileItem *)itemWithPath:(NSString *)path withType:(LMFileType)type {
    LMFileItem *item = [[LMFileItem alloc] init];
    item.path = path;
    item.isSelected = NO;
    item.type = type;
    item.isDeleted = NO;
    return item;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _size = nil;
    }
    return self;
}


// TODO turn to dict
+ (NSString *)getLMFileTypeName:(LMFileType)type {
    static NSDictionary *fileTypeDict;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileTypeDict = @{
                @(LMFileTypeBundle): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_1", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeSupport): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_2", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeCache): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_3", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypePreference): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_4", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeState): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_5", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeReporter): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_6", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeLog): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_7", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeSandbox): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_8", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeDaemon): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_9", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeLoginItem): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_10", nil, [NSBundle bundleForClass:[self class]], @""),

                @(LMFileTypeKextWithPath): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_11", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeKextWithBundleId): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_12", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeSignal): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_13", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypeFileSystem): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_14", nil, [NSBundle bundleForClass:[self class]], @""),
                @(LMFileTypePreferencePane): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_15", nil, [NSBundle bundleForClass:[self class]], @""),


                @(LMFileTypeOther): NSLocalizedStringFromTableInBundle(@"LMFileItem_getLMFileTypeName_1553153166_99", nil, [NSBundle bundleForClass:[self class]], @"")

        };
    });


    return fileTypeDict[@(type)];
}

- (NSString *)name {
    return [self.path lastPathComponent];
}

- (NSImage *)icon {
    if (_type == LMFileTypeLoginItem) {
        return [NSImage imageNamed:@"login_item" withClass:self.class];
    } else if (_type == LMFileTypeKextWithPath || _type == LMFileTypeKextWithBundleId) {
        return [NSImage imageNamed:@"kernel_extension" withClass:self.class];
    } else if (_type == LMFileTypeSignal) {
        return [NSImage imageNamed:@"running_app" withClass:self.class];
    }
    return [[NSWorkspace sharedWorkspace] iconForFile:self.path];
}

- (NSInteger)size {
    if (!_size) {

        // 优先使用 mdls 或获取大小(直接获取)
        NSInteger size = 0;
        if ([self.path stringByAppendingString:@".app"]) {
            size = [MdlsToolsHelper getAppSizeByPath:self.path andFileType:@"app"];
        }
        if (size <= 0) {
            size = (NSInteger) [[NSFileManager defaultManager] diskSizeAtPath:self.path];
        } else {
            NSLog(@"app path is %@, size is %ld", self.path, size);
        }
        _size = @(size);
    }
    return [_size integerValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"path:%@, isSelected:%d", self.path, self.isSelected];
}
//- (BOOL)isEqual:(id)object {
//    NSLog(@"%s, object:%@, self:%@", __FUNCTION__,  object, self);
////    if (![object isKindOfClass:self.class]) {
////        return NO;
////    }
//    LMFileItem *obj = object;
//    return [self.path isEqualToString:obj.path];
//}

+ (BOOL)needShowPath:(LMFileItem *)fileItem {
    return !(fileItem.type == LMFileTypeKextWithBundleId || fileItem.type == LMFileTypeSignal || fileItem.type == LMFileTypeLoginItem);
}

@end
