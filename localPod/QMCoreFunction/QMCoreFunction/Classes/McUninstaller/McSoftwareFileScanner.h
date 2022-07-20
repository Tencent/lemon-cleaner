//
//  McSoftwareFileScanner.h
//  QMUnintallDemo
//
//  
//  Copyright (c) 2013年 haotan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMCoreFunction/McLocalSoft.h"

enum
{
    McSoftwareFileBundle=1,
    McSoftwareFileSupport,
    McSoftwareFileCache,
    McSoftwareFilePreference,
    McSoftwareFileState,
    McSoftwareFileReporter,
    McSoftwareFileLog,
    McSoftwareFileSandbox,
    McSoftwareFileDaemon,
    McSoftwareFileUnname,
    McSoftwareFileOther
};
typedef NSInteger McSoftwareFileType;

static NSString const *SoftwareFileTypeName[12] = {
    @"",
    @"程序文件",
    @"支持文件",
    @"缓存文件",
    @"设置文件",
    @"程序状态文件",
    @"崩溃日志",
    @"程序日志",
    @"沙盒文件",
    @"登录项",
    @"未知文件",
    @"其他文件"
    };

@interface McUninstallItemTypeGroup : NSObject
@property (nonatomic, assign) McSoftwareFileType fileType;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign, readonly) NSControlStateValue selectedState;
@property (nonatomic, assign, readonly) NSInteger selectedCount;
@property (nonatomic, assign, readonly) NSInteger selectedSize;
@end

@interface McSoftwareFileItem : NSObject
@property (nonatomic,strong) NSString *filePath;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSImage *icon;
@property (nonatomic,assign) size_t fileSize;
@property (nonatomic,assign) McSoftwareFileType type;
@property (nonatomic,assign) BOOL isSelected;

+ (McSoftwareFileItem *)itemWithPath:(NSString *)filePath;
+ (NSString *)typeName:(McSoftwareFileType)type;

@end


@interface McSoftwareFileScanner : NSObject
@property (nonatomic, strong) McLocalSoft *soft;
@property (nonatomic, readonly) NSDictionary *pathInfo;
@property (nonatomic, readonly) NSArray *items;

+ (id)scannerWithPath:(NSString *)filePath;
+ (id)scannerWithSoft:(McLocalSoft *)soft;

- (void)start;

@end
